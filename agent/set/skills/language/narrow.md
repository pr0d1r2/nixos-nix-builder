Only add words to narrow-language dictionaries that exist in this repo:

- `.narrow-language-nix.dic` — for `*.nix` files
- `.narrow-language-shell.dic` — for `*.sh` and `*.bats` files
- `.narrow-language-markdown.dic` — for `*.md` files
- `.narrow-language-other.dic` — for `*.yml`, `*.yaml`, `*.toml`,
  `*.tcl`, `justfile`

Do not create or add words to dictionaries for languages not
present in this repo.

When narrow-language hook reports unknown words, add them to
the correct dictionary file (one word per line, sorted
alphabetically). Add only words used by files staged in the
current commit — the compact hook removes words not referenced
by staged files.
