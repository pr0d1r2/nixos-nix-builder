Before starting a new QEMU instance, clean up leftovers from
previous runs:

- Kill stale QEMU processes holding the SSH forwarding port
  (default 2222). Use `pkill -f` matching the port pattern.
- Remove stale boot directories (`boot/`) to force fresh kernel
  extraction. Cached files from a previous ISO cause mismatches.
- Wait briefly (~0.5s) after killing for the port to release.

Stale QEMU processes commonly survive after interrupted smoke
tests, expect timeouts, or Ctrl-C during boot.
