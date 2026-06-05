{ lib, ... }:

let
  raw = builtins.readFile ../secrets/authorized_keys;
  lines = lib.splitString "\n" raw;
  keys = builtins.filter (l: l != "" && !lib.hasPrefix "#" l) lines;
in
{
  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
      X11Forwarding = false;
      MaxAuthTries = 3;
      LoginGraceTime = 30;
      AllowTcpForwarding = "local";
      AllowAgentForwarding = false;
    };
  };

  environment.etc = {
    "ssh/ssh_host_ed25519_key" = {
      source = ../secrets/ssh_host_ed25519_key;
      mode = "0600";
    };
    "ssh/ssh_host_ed25519_key.pub" = {
      source = ../secrets/ssh_host_ed25519_key.pub;
      mode = "0644";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = keys;
}
