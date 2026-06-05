Integration tests share health checks via a common Tcl library.

`tests/integration/lib/health-checks.tcl` defines all SSH-based
health checks in one place. Both `smoke.exp` and `live.exp` call
`run_health_checks` with a label, expected hostname, and optional
skip_tags list.

skip_tags control environment-specific sections:

- `hardware` — KVM device, microcode, real storage tiers
- `network` — interface UP, default route
- `mdns` — avahi publish/resolve

Smoke tests skip hardware/network/mdns (QEMU SLIRP differs).
Live tests run all checks.

When adding a new health check, add it to health-checks.tcl —
not to individual .exp files. The .exp files are thin wrappers
for boot/connection setup.
