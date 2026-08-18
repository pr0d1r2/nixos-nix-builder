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
    set-and-setting.lib.mkConsumerFlake {
      inherit self nixpkgs set-and-setting;
      lib = set-and-setting.lib // {
        checksFor =
          args:
          (set-and-setting.lib.checksFor (
            args
            // {
              fragments = builtins.filter (fragment: fragment != "actions") args.fragments;
            }
          ))
          // {
            actionlint =
              args.pkgs.runCommand "actionlint-check"
                {
                  nativeBuildInputs = [
                    args.pkgs.actionlint
                    args.pkgs.findutils
                  ];
                }
                ''
                  cd ${args.src}
                  mapfile -t workflows < <(find .github/workflows -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)
                  actionlint "''${workflows[@]}"
                  touch $out
                '';
          };
      };
      fragments = [
        "base"
        "actions"
        "nix"
        "shell"
        "ascii"
        "markdown"
        "yaml"
      ];
      src = ./.;
    };
}
