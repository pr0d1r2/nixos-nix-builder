Run operations on the remote builder first. Fall back to the
local Mac only when the builder is unreachable.

Remote machines are faster (dedicated CPU, more RAM, native
x86_64) and avoid cross-architecture overhead. The Mac is a
development host, not a build/burn target.

Pattern for remote-first scripts:

1. Attempt the operation on the builder via SSH.
2. On success, exit 0.
3. On connection failure (exit 255 or exit 2), fall back to
   the local equivalent.
4. On operation failure (any other non-zero exit), propagate
   the error -- do not silently retry locally.

Scripts using this pattern: burn-auto.sh, burn-confirmed.sh,
smoke-remote.sh.
