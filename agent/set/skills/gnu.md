Prefer GNU versions of command-line tools over BSD equivalents.
The dev shell provides GNU coreutils, grep, sed, gawk, findutils
via nixpkgs so scripts behave identically on macOS and Linux.

Never use `/usr/bin/` paths — always rely on dev shell PATH which
resolves to GNU variants.
