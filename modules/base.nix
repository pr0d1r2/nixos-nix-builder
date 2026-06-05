{ lib, pkgs, ... }:

let
  configDir = ../config/user;
  readConfig =
    file: default:
    if builtins.pathExists (configDir + "/${file}") then
      lib.strings.trim (builtins.readFile (configDir + "/${file}"))
    else
      default;
in
{
  image.baseName = lib.mkForce "nixos-nix-builder";

  networking = {
    hostName = "nix-builder";
    domain = "local";
    networkmanager.enable = true;
  };

  time.timeZone = lib.mkDefault (readConfig "timezone" "Europe/Warsaw");
  i18n.defaultLocale = readConfig "locale" "en_US.UTF-8";
  console.keyMap = readConfig "keymap" "us";

  services.timesyncd.enable = true;

  environment.systemPackages = with pkgs; [
    util-linux
    coreutils
    e2fsprogs
    pciutils
    usbutils
    htop
    tmux
    rsync
  ];
}
