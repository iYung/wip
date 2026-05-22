## CI Checklist

- [x] Create workflow — `.github/workflows/ci.yml` — add a GitHub Actions workflow that triggers on push to `main` and PRs targeting `main`, installs LÖVE 11.5 via `ppa:bartbes/love-stable` on `ubuntu-latest`, checks out the repo, and runs `love . --headless`; exit code drives pass/fail
