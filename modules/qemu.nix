{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    qemu
  ];

  virtualisation.libvirtd.enable = false;
}
