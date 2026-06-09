# Cloudflare Pages Migration Design

## Goal

Migrate all web deploys — production (main branch) and PR previews — from GitHub Pages to Cloudflare Pages. GitHub Pages enforces a 10-builds/hour limit that causes CI failures when multiple PRs push frequently. Cloudflare Pages Direct Upload has no equivalent rate limit.

---

## Affected files

| File | Change |
|------|--------|
| `.github/workflows/web.yml` | Replace all `peaceiris/actions-gh-pages` steps and the Pages polling loop with `wrangler pages deploy` calls; add CF secret env vars; simplify cleanup job |

No Lua, build script, or test changes needed.

---

## What changes

### 1. One-time setup (manual, pre-merge)

Before the workflow changes land, the repo owner must:

1. **Create the Cloudflare Pages project** (run once locally or in CF dashboard):
   ```bash
   npx wrangler pages project create wip --production-branch=main
   ```
   This creates a project named `wip` at `https://wip.pages.dev`.

2. **Add two secrets to the GitHub repo** (Settings → Secrets → Actions):
   - `CLOUDFLARE_API_TOKEN` — a CF API token with *Cloudflare Pages: Edit* permission
   - `CLOUDFLARE_ACCOUNT_ID` — found in CF dashboard sidebar (Account ID)

### 2. `deploy` job (main → production)

**Before:** `peaceiris/actions-gh-pages` pushes `web/` to the `gh-pages` branch root.

**After:** `wrangler pages deploy` uploads `web/` directly to Cloudflare Pages as the production deployment.

```yaml
- name: Deploy to Cloudflare Pages (production)
  run: npx wrangler pages deploy ./web --project-name=wip --branch=main
  env:
    CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
    CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
```

New production URL: `https://wip.pages.dev`

### 3. `deploy-pr` job (PR → preview)

**Before:** Pushes `web/` to `pr-<number>/` subdirectory on `gh-pages`, then polls GitHub Pages API for up to 5 minutes waiting for the build to become live.

**After:** `wrangler pages deploy` uploads directly; no polling needed — wrangler exits only after the deployment is live. Cloudflare Pages automatically creates a stable alias URL per branch.

```yaml
- name: Deploy PR preview to Cloudflare Pages
  run: npx wrangler pages deploy ./web --project-name=wip --branch=pr-${{ github.event.pull_request.number }}
  env:
    CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
    CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
```

Preview URL (deterministic, no parsing needed): `https://pr-<number>.wip.pages.dev`

The PR comment body updates to use this URL.

### 4. `cleanup-pr` job (PR closed)

**Before:** Checks out the `gh-pages` branch, runs `git rm`, commits and pushes.

**After:** Calls the Cloudflare API to list and delete all deployments for the closed PR's branch. This avoids needing `contents: write` permission.

```bash
DEPLOYMENTS=$(curl -s "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/pages/projects/wip/deployments?branch=pr-$PR_NUMBER" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" | jq -r '.result[].id')
for id in $DEPLOYMENTS; do
  curl -s -X DELETE "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/pages/projects/wip/deployments/$id?force=true" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
done
```

### 5. Permissions block

`contents: write` and `pages: read` are no longer needed. Only `pull-requests: write` (for posting comments) remains.

---

## What stays the same

- `build` job — identical; still produces the `web-build` artifact
- Artifact upload/download between jobs
- `npm install` + `bash scripts/build_web.sh` commands
- CI test workflow (`ci.yml`) — untouched
- PR comment mechanism (`peter-evans/create-or-update-comment`)
- Trigger events (`push`, `pull_request` types, `workflow_dispatch`)

---

## Open questions

1. **`wrangler` version** — `web.yml` uses `npm install` to install project deps. `wrangler` should be added to `package.json` as a dev dependency (pinned) so the version is reproducible and the `npx wrangler` calls resolve from the local install rather than fetching the latest each run.

2. **Production URL change** — moving from `https://iyung.github.io/wip/` to `https://wip.pages.dev`. Any saved links (PR descriptions, README, memory) need updating. The old GitHub Pages URL can be kept alive by leaving the `gh-pages` branch in place, but it will no longer receive new deploys.

3. **`gh-pages` branch** — after migration, the branch becomes stale. It can be deleted once the team is confident in the new setup. The checklist task should note this as an optional follow-up.
