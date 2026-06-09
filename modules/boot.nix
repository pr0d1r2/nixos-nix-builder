{ lib, ... }:
{
  boot = {
    kernelParams = [
      "nomodeset"
      "consoleblank=1"
    ];
    loader.timeout = lib.mkForce 1;
  };

  isoImage = {
    forceTextMode = true;
    prependToMenuLabel = "nixos-nix-builder";
    appendToMenuLabel = "";
  };
}
