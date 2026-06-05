Product management lives in-repo, not in external tools.

## Release workflow

1. Daily coding sessions append to `## Unreleased` in `CHANGELOG.md` as features land.
2. When a release is ready: rename `## Unreleased` to `## YYYY-MM-DD (short-sha)`, add a fresh `## Unreleased` section, commit, tag, build ISO.
3. Each release produces a bootable ISO that gets burned to USB and deployed to hardware.

## CHANGELOG.md

Single source of truth for what changed and when. Group entries by theme (e.g. "Firewall hardening", "Integration testing"), not by commit. Write entries for the operator, not the developer — focus on what the release delivers, not implementation details.

After completing work on a feature or fix, append a one-line entry to the relevant group under `## Unreleased`. Create a new group heading if nothing fits.

## Commit cadence vs release cadence

Commits happen continuously during a session (one per decision). Releases happen when the `## Unreleased` section represents a coherent, tested, deployable state — typically at the end of a coding day or after a milestone.

## What triggers a release

- Hardware/driver changes that need to reach the pendrive
- Game launcher or storage logic fixes
- Accumulated quality-of-life improvements worth burning a new ISO for

There is no fixed schedule. Release when the unreleased work is worth deploying.
