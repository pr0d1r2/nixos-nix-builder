{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "builder"
      ];
      substituters = [
        "https://cache.nixos.org"
        "https://pr0d1r2.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM="
      ];
      sandbox = true;
      max-jobs = "auto";
      cores = 0;
      build-dir = "/mnt/storage/nix-builds";
    };
  };
}
