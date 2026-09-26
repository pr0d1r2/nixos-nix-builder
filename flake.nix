{
  description = "CHANGEME";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";

    set-and-setting.url = "github:pr0d1r2/set-and-setting";
    set-and-setting.inputs.nixpkgs-lock.follows = "nixpkgs-lock";
  };

  outputs =
    {
      self,
      nixpkgs,
      set-and-setting,
      ...
    }:
    (import ./nix/outputs.nix {
      inherit self nixpkgs set-and-setting;
    })
    // {
      devShells = nixpkgs.lib.mapAttrs (
        system: shells:
        nixpkgs.lib.mapAttrs (
          _name: shell: shell.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ nixpkgs.legacyPackages.${system}.actionlint ];
          })
        ) shells
      ) (import ./nix/outputs.nix {
        inherit self nixpkgs set-and-setting;
      }).devShells;
    };
}
