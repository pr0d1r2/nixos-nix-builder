{
  self,
  nixpkgs,
  set-and-setting,
  ...
}:
let
  supportedSystems = [
    "aarch64-darwin"
    "x86_64-darwin"
    "x86_64-linux"
    "aarch64-linux"
  ];
  forAllSystems =
    f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});

  fragments = [
    "base"
    "nix"
    "shell"
    "ascii"
    "markdown"
    "yaml"
  ];

  system = "x86_64-linux";
in
{
  packages = forAllSystems (
    pkgs:
    {
      setting = (set-and-setting.lib.mkSetting { inherit pkgs; }).materialized;
    }
    // nixpkgs.lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == system) rec {
      iso = self.nixosConfigurations.nixos-nix-builder.config.system.build.isoImage;
      default = iso;
    }
  );

  devShells = forAllSystems (
    pkgs:
    let
      mat = set-and-setting.lib.materializationFor { inherit pkgs fragments; };
      sys = pkgs.stdenv.hostPlatform.system;
    in
    set-and-setting.lib.mkDevShells {
      inherit pkgs;
      basePackages = mat.packages;
      defaultShellHook = ''
        ${self.packages.${sys}.setting}/bin/sync-setting .
        cp -f ${mat.files}/lefthook.yml lefthook.yml
      '';
    }
  );

  checks = forAllSystems (
    pkgs:
    (set-and-setting.lib.checksFor {
      inherit pkgs fragments;
      src = ./..;
    })
    // {
      dep-graph = set-and-setting.lib.mkDepGraphCheck {
        inherit pkgs;
        projectRoot = ./..;
      };
      default = pkgs.runCommand "checks" { } "touch $out";
    }
  );

  apps = forAllSystems (pkgs: {
    confirm = {
      type = "app";
      program = "${
        pkgs.writeShellApplication {
          name = "confirm";
          runtimeInputs = (set-and-setting.lib.materializationFor { inherit pkgs fragments; }).packages ++ [
            pkgs.diffutils
            pkgs.findutils
            pkgs.gawk
            pkgs.gnugrep
          ];
          runtimeEnv = {
            FRAGMENTS_DIR = "${set-and-setting}/setting/integrations/lefthook";
            ASSEMBLE_SCRIPT = "${set-and-setting}/setting/lib/assemble-lefthook.sh";
            DETECT_SCRIPT = "${set-and-setting}/setting/lib/detect-fragments.sh";
            SETTING_SRC = "${self.packages.${pkgs.stdenv.hostPlatform.system}.setting}";
            CONFIRM_SCRIPT = "${set-and-setting}/lib/confirm.sh";
            CONFIRM_REV = set-and-setting.rev or "unknown";
          };
          text = builtins.readFile ../scripts/confirm.sh;
        }
      }/bin/confirm";
    };
  });

  nixosConfigurations.nixos-nix-builder =
    let
      ts = self.lastModifiedDate or "00000000000000";
      shortRev = self.shortRev or "dirty";
      date = builtins.substring 0 8 ts;
      time = builtins.substring 8 4 ts;
    in
    nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ../modules
        {
          system.nixos.label = nixpkgs.lib.mkForce "${date}-${time}-${shortRev}";
          system.nixos.distroName = nixpkgs.lib.mkForce " ::";
        }
      ];
    };
}
