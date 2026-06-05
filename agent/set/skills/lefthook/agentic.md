Lefthook output follows Unix philosophy: no output means success.

Use `output` in `lefthook.yml` to list only the sections shown.
Set `output: [failure]` to show only failed hooks and their error
output. All other output (banner, skip lines, success marks,
run logs) is hidden.

On success: zero output.
On failure: hook name + error + fix instructions.

Never add `meta`, `summary`, `success`, `skips`, or
`execution_out` to the output list — those produce noise
that hides real errors.
