Use direct kernel boot (`-kernel`/`-initrd`/`-append`) for QEMU
smoke tests instead of GRUB boot (`-boot d`). Direct boot is
faster (~18s vs ~45s) and guarantees serial console output.

NixOS ISO kernel layout differs from standard ISOs:

- Kernel: `boot/nix/store/<hash>-linux-<ver>/bzImage`
- Initrd: `boot/nix/store/<hash>-initrd-<ver>/initrd`
- grub.cfg: `EFI/BOOT/grub.cfg` (not `boot/grub/grub.cfg`)

Use `find` to locate bzImage and initrd by name — paths change
with every build. Extract the full kernel command line from
grub.cfg including `root=LABEL=...` and `init=...` — omitting
root= causes "root device not found" at boot.
