QEMU guests running NixOS boot Avahi and advertise the same
hostname as the builder host. This poisons the macOS mDNS cache
with the guest's SLIRP address (10.0.2.15), making the real
builder unreachable by hostname after the guest exits.

After any QEMU guest shutdown or kill:

1. Flush macOS mDNS cache (`dscacheutil -flushcache`,
   `killall -HUP mDNSResponder`).
2. Wait for the real builder's Avahi to re-advertise (~3-5s).
3. Expect SSH host key mismatches if known_hosts cached the
   guest's key. Clear stale entries before reconnecting.
