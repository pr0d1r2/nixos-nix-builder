Always use `find` and `xargs` from the dev shell (nixpkgs
`findutils`). BSD find on macOS lacks `-printf`, has different
`-regex` syntax, and BSD xargs lacks the `-d` delimiter flag.
