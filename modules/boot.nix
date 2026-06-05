{ lib, ... }:
{
  boot = {
    kernelParams = [
      "nomodeset"
      "consoleblank=1"
      "console=tty0"
      "console=ttyS0,115200"
    ];
    loader.timeout = lib.mkForce 1;
  };

  isoImage = {
    forceTextMode = true;
    prependToMenuLabel = "nixos-nix-builder";
    appendToMenuLabel = "";
  };
}
