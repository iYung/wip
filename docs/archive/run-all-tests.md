## Run All Tests Checklist

- [x] Task 1 — `lua/headless/runner.lua` — Add a nil-file branch to `runner.run`. When `test_file` is nil, call `love.filesystem.getDirectoryItems("tests")`, filter for files ending in `.lua`, sort them alphabetically, then loop over them in series: run each with `pcall(dofile, "tests/" .. filename)`, print `PASS  tests/<name>` or `FAIL  tests/<name> — <err>` per file, accumulate a failure flag. After the loop print `N/M passed`. Call `love.event.quit(0)` if all passed, `love.event.quit(1)` otherwise. The existing single-file path (when `test_file` is not nil) must remain unchanged.

- [x] Task 2 — `coding-notes.md` — Add a third example under the **Running Tests** section: `love . --headless` with a comment `# run all tests`. Place it after the existing two examples.
