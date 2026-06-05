Gate integration test hooks on host reachability.

Pre-push hooks that require a remote host (builder, live node)
must skip silently when the host is unreachable. Exit 0 on
skip — a non-zero exit blocks the push.

Pattern:

1. Ping-wait the target host.
2. Unreachable → print skip message, exit 0.
3. Reachable → run integration test, propagate exit code.

Optional: check a marker file to skip if already passed for
HEAD SHA (smoke-conditional uses smoke-check.sh).

Scripts: `scripts/lefthook/smoke-conditional.sh`,
`scripts/lefthook/live-conditional.sh`.
