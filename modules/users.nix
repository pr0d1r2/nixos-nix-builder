{ lib, pkgs, ... }:

let
  authKeysPath = ../secrets/authorized_keys;
  raw = if builtins.pathExists authKeysPath then builtins.readFile authKeysPath else "";
  lines = lib.splitString "\n" raw;
  keys = builtins.filter (l: l != "" && !lib.hasPrefix "#" l) lines;
in
{
  users = {
    mutableUsers = false;

    users.builder = {
      isNormalUser = true;
      uid = 1000;
      group = "builder";
      description = "Nix builder";
      extraGroups = [
        "wheel"
        "networkmanager"
        "kvm"
      ];
      initialHashedPassword = "";
      openssh.authorizedKeys.keys = keys;
      shell = pkgs.bashInteractive;
    };
    groups.builder.gid = 1000;

    users.nixos = {
      isNormalUser = lib.mkForce false;
      isSystemUser = lib.mkForce true;
      uid = 999;
      group = "nixos";
    };
    groups.nixos.gid = 999;
  };

  services.getty.autologinUser = lib.mkForce "builder";
}
