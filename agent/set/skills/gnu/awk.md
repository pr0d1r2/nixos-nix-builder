Always use `gawk` from the dev shell (nixpkgs `gawk`). BSD awk
on macOS lacks `gensub()`, `FPAT`, `nextfile`, `@include`, and
other GNU extensions.
