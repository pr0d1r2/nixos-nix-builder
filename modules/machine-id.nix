_:

{
  # Stable machine-id derived from: echo -n "nixos-nix-builder" | md5sum
  environment.etc."machine-id" = {
    text = "5b23f4305970f426c3d1c00d0c2aa0e3\n";
    mode = "0444";
  };
}
