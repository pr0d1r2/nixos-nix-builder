{ pkgs, ... }:
{
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = false;
      userServices = true;
      workstation = false;
    };
    openFirewall = true;
  };

  systemd.services.avahi-alias-nix-serve = {
    description = "Publish nix-serve.local mDNS alias";
    after = [
      "avahi-daemon.service"
      "network-online.target"
    ];
    requires = [ "avahi-daemon.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.avahi ];
    serviceConfig = {
      ExecStart = "${pkgs.bash}/bin/bash ${../fragments/avahi-alias-nix-serve.sh}";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
