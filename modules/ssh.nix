{ lib, ... }:

let
  authKeysPath = ../secrets/authorized_keys;
  raw = if builtins.pathExists authKeysPath then builtins.readFile authKeysPath else "";
  lines = lib.splitString "\n" raw;
  keys = builtins.filter (l: l != "" && !lib.hasPrefix "#" l) lines;

  hostKeyPath = ../secrets/ssh_host_ed25519_key;
  hostKeyPubPath = ../secrets/ssh_host_ed25519_key.pub;
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

  environment.etc =
    lib.optionalAttrs (builtins.pathExists hostKeyPath) {
      "ssh/ssh_host_ed25519_key" = {
        source = hostKeyPath;
        mode = "0600";
      };
    }
    // lib.optionalAttrs (builtins.pathExists hostKeyPubPath) {
      "ssh/ssh_host_ed25519_key.pub" = {
        source = hostKeyPubPath;
        mode = "0644";
      };
    };

  users.users.root.openssh.authorizedKeys.keys = keys;
}
