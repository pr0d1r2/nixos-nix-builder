{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      5000
    ];
    allowedUDPPorts = [
      5353
    ];
  };
}
