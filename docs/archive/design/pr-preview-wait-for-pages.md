# PR Preview — Wait for Pages Before Posting Link

## Goal

The PR comment containing the web preview link should only appear after GitHub Pages has finished serving the new build. Currently the comment is posted right after the gh-pages push, which means the link is live in the PR before the site is accessible.

## Affected files

- `.github/workflows/web.yml` — the `deploy-pr` job

## What changes

After the `peaceiris/actions-gh-pages` step deploys the PR preview to gh-pages, add a polling step that waits for the corresponding GitHub Pages deployment to reach `built` before posting the PR comment.

**Approach — GitHub Pages Deployments API**

1. Record a `start_time` (ISO-8601) immediately before the gh-pages push step.
2. After the push, poll `GET /repos/{owner}/{repo}/pages/deployments` (via `gh api`) every 15 seconds.
3. Find the deployment whose `created_at` is ≥ `start_time` (i.e., the one our push triggered).
4. Wait until that deployment's `status` is `built`.
5. Once confirmed, post the PR comment.
6. If no `built` deployment is found within 5 minutes, exit non-zero to fail the job.

This correctly handles:
- **New PRs**: the very first preview deployment is waited on.
- **Updated PRs**: each new push creates a fresh Pages deployment with a new ID; we track by `created_at` so we always wait on the right one.

## What stays the same

- `build` job is unchanged.
- `deploy` job (main branch) is unchanged.
- `cleanup-pr` job is unchanged.
- The comment body and format are unchanged.
- `deploy-pr` still uses `peaceiris/actions-gh-pages` for the actual deploy.

## Open questions

None — all resolved before writing this doc.
- Detection method: GitHub Pages deployments API (not URL polling).
- Timeout behavior: fail the job after ~5 minutes.
