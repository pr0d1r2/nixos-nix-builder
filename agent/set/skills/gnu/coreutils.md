Always use coreutils from the dev shell (nixpkgs `coreutils`).
On macOS the built-in versions are BSD and differ from GNU:
`sort -V` (version sort) is GNU-only, `readlink -f` is missing,
`stat` syntax is incompatible, `date -d` does not exist.
