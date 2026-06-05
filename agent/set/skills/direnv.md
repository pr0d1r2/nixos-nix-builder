Flake entrypoint should be direnv via .envrc file.
File .envrc should watch flake and its modules and files they depend on for changes to reload.

When you change `flake.nix`, `flake.lock`, or any watched file, direnv must reload before new packages or shell hooks take effect. Run `direnv reload` after such changes.

If direnv prints `direnv: error .envrc is blocked`, run `direnv allow` to unblock it.

When a command fails with "command not found" for a tool that should be in the dev shell, the likely cause is a stale direnv environment. Run `direnv reload` before investigating further.
