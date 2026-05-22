# CI

## Goal

Run the headless test suite automatically on every push and pull request so regressions are caught before merge.

## Affected files

- `.github/workflows/ci.yml` — new file (entire CI definition)

## What changes

A single GitHub Actions workflow is added. It:

1. Triggers on `push` to `main` and on `pull_request` targeting `main`.
2. Runs on `ubuntu-latest`.
3. Installs LÖVE 11.5 via the `ppa:bartbes/love-stable` PPA.
4. Checks out the repo.
5. Runs `love . --headless` (no test file argument = runner discovers and runs all `tests/*.lua`).
6. Passes if the process exits 0; fails if it exits 1 (runner prints which test files failed before quitting).

## What stays the same

- Test files, runner logic, and headless stubs are unchanged.
- No linter or static analysis step — the existing test suite is the only check.
- No caching needed; the PPA install is fast and there are no package managers (npm, cargo, etc.) to cache.

## Open questions

None.
