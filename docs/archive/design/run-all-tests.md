## Goal

Add `love . --headless` (no test file argument) as a command that discovers and runs every test in `tests/` in series, prints a per-file pass/fail line, then exits 0 (all passed) or 1 (any failed).

## Affected files

- `lua/headless/runner.lua` — extend `runner.run` to handle a `nil` test_file
- `coding-notes.md` — document the new invocation

## What changes

**`runner.run(test_file)`** gains a nil-file branch:
- Calls `love.filesystem.getDirectoryItems("tests")` to get all filenames
- Filters for `.lua` files, sorts alphabetically
- Runs each via `dofile` in a `pcall`, accumulates pass/fail per file
- Prints one `PASS  tests/foo.lua` or `FAIL  tests/foo.lua — <err>` line per file
- Prints a final summary: `N/M passed`
- Calls `love.event.quit(0)` if all pass, `love.event.quit(1)` if any fail

The single-file path (`runner.run("tests/foo.lua")`) is unchanged.

`love.filesystem` is already live in headless mode — `conf.lua` only disables window/graphics/audio modules, not filesystem. `stubs.lua` only overrides `getInfo`, leaving `getDirectoryItems` intact.

**`coding-notes.md`** gains a third invocation example in the Running Tests section:

```bash
# run all tests
love . --headless
```

## What stays the same

- `--visual` path is untouched
- `conf.lua` is untouched
- `main.lua` is untouched (already passes `nil` to `runner.run` when no file arg is given)
- Single-file invocation `love . --headless tests/foo.lua` is unchanged

## Open questions

None.
