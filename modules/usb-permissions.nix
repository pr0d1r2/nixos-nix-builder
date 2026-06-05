{
  services.udev.extraRules = ''
    SUBSYSTEM=="block", ACTION=="add", ENV{ID_BUS}=="usb", GROUP="builder", MODE="0660"
  '';
}
