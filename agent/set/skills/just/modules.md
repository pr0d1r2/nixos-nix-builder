When the top-level justfile grows past ~20 recipes, group cohesive
sub-commands into a module file rather than adding more flat recipes.

## Layout

Module files live in `just/<module>.just`. The root justfile stays
tiny and declares each module with a single line:

```just
# Build, burn-prep, and smoke-test the ISO.
mod build 'just/build.just'

# Run and manage agent trips on the live node.
mod trip 'just/trip.just'

# Update pinned inputs (flake, Claude, scan reports).
mod update 'just/update.just'
```

The comment directly above each `mod` line becomes the module's
description in `just --list`, so root output stays self-describing.

Invocation becomes `just <module> <recipe> [args]`, e.g.
`just trip run hello-world`, `just build iso`, `just update flake`.

## Module file template

Every module file must:

1. Pin its working directory back to the repo root so relative
   script paths keep working:
   ```just
   set working-directory := '..'
   ```

2. Define a private `default` recipe that lists the module's own
   recipes with a `just <module>` prefix (plus a trailing space),
   for copy-paste from `just <module>`:
   ```just
   [private]
   default:
       @just --list <module> --list-prefix "    just <module> "
   ```

3. Name recipes as short sub-verbs (`run`, `upload`, `list`, `test`)
   — the module name already supplies the noun.

## When to keep a recipe flat

Keep at the root of `justfile` any recipe that is:

- a single-command operator shortcut with no natural siblings
  (`agent`, `claude`, `htop`, `iotop`),
- a standalone verb that doesn't cluster with others (`burn`,
  `config`),
- or a shared healthcheck invoked against multiple hosts
  (`live`, `booted`, `reboot`).

Groups form from three or more cohesive siblings. Two siblings stay
flat — promoting them to a module adds typing for no clarity gain.
