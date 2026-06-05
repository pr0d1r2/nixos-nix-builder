Integration tests targeting remote hosts must fast-fail on
connectivity before running checks.

Pattern (`scripts/lib/ssh-wait.sh`):

1. Ping with exponential backoff: 1s, 2s, 5s timeouts.
   Fail immediately after third ping failure.
2. SSH with same exponential backoff: 1s, 2s, 5s timeouts.
   Fail after third SSH failure.
3. On first SSH success, proceed to health checks.

Total wait ≤ 16s before declaring host unreachable. Avoids
the default 60s SSH wait that blocks the operator when the
builder is powered off or unreachable.
