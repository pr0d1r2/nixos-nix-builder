Use `glob` instead of `exclude` in lefthook command overrides.

`exclude` does not reliably filter files from remote-defined
commands. Use `glob` to restrict which staged files reach the
command.

Use `**/*.ext` for files in subdirectories. Plain `*.ext` only
matches root-level files — nested paths like
`tests/integration/lib/foo.tcl` are silently skipped.
