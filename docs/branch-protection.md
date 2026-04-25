# Branch protection setup — `gh` CLI commands

Run these commands **after** creating the repository on GitHub.
They work on both **Windows** (PowerShell or Command Prompt) and **Linux/macOS** (bash/zsh).

> **Prerequisites**
> - [GitHub CLI](https://cli.github.com/) installed and authenticated (`gh auth login`)
> - You are the repository owner / sole maintainer
> - Replace `IgnitedLabs` and `chrome-devtools-mcp-canister` with your actual values

---

## 1 — Set your repo variables (set once per shell session)

**Linux / macOS (bash/zsh)**
```bash
REPO_OWNER="IgnitedLabs"
REPO_NAME="chrome-devtools-mcp-canister"
BRANCH="main"
```

**Windows (PowerShell)**
```powershell
$REPO_OWNER = "IgnitedLabs"
$REPO_NAME  = "chrome-devtools-mcp-canister"
$BRANCH     = "main"
```

**Windows (Command Prompt)**
```cmd
set REPO_OWNER=IgnitedLabs
set REPO_NAME=chrome-devtools-mcp-canister
set BRANCH=main
```

---

## 2 — Enable branch protection with required status checks

This rule enforces that all three CI jobs must pass before any PR can merge
into `main`.  As a solo maintainer you also need `--include-admins` so the
rule applies to yourself (otherwise you could bypass it).

**Linux / macOS**
```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO_OWNER}/${REPO_NAME}/branches/${BRANCH}/protection" \
  -f "required_status_checks[strict]=true" \
  -f "required_status_checks[contexts][]=build" \
  -f "required_status_checks[contexts][]=MCP smoke test (initialize)" \
  -f "required_status_checks[contexts][]=Browser probe (Chrome launch + navigate)" \
  -F "enforce_admins=true" \
  -F "required_pull_request_reviews=null" \
  -F "restrictions=null" \
  -F "allow_force_pushes=false" \
  -F "allow_deletions=false" \
  -F "block_creations=false"
```

**Windows (PowerShell)**
```powershell
gh api `
  --method PUT `
  -H "Accept: application/vnd.github+json" `
  "/repos/$REPO_OWNER/$REPO_NAME/branches/$BRANCH/protection" `
  -f "required_status_checks[strict]=true" `
  -f "required_status_checks[contexts][]=build" `
  -f "required_status_checks[contexts][]=MCP smoke test (initialize)" `
  -f "required_status_checks[contexts][]=Browser probe (Chrome launch + navigate)" `
  -F "enforce_admins=true" `
  -F "required_pull_request_reviews=null" `
  -F "restrictions=null" `
  -F "allow_force_pushes=false" `
  -F "allow_deletions=false" `
  -F "block_creations=false"
```

**Windows (Command Prompt)**
```cmd
gh api ^
  --method PUT ^
  -H "Accept: application/vnd.github+json" ^
  /repos/%REPO_OWNER%/%REPO_NAME%/branches/%BRANCH%/protection ^
  -f "required_status_checks[strict]=true" ^
  -f "required_status_checks[contexts][]=build" ^
  -f "required_status_checks[contexts][]=MCP smoke test (initialize)" ^
  -f "required_status_checks[contexts][]=Browser probe (Chrome launch + navigate)" ^
  -F "enforce_admins=true" ^
  -F "required_pull_request_reviews=null" ^
  -F "restrictions=null" ^
  -F "allow_force_pushes=false" ^
  -F "allow_deletions=false" ^
  -F "block_creations=false"
```

---

## 3 — Allow GitHub Actions (and Renovate) to merge via auto-merge

GitHub auto-merge requires the repository setting to be enabled:

**Linux / macOS**
```bash
gh api \
  --method PATCH \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO_OWNER}/${REPO_NAME}" \
  -F "allow_auto_merge=true" \
  -F "delete_branch_on_merge=true"
```

**Windows (PowerShell)**
```powershell
gh api `
  --method PATCH `
  -H "Accept: application/vnd.github+json" `
  "/repos/$REPO_OWNER/$REPO_NAME" `
  -F "allow_auto_merge=true" `
  -F "delete_branch_on_merge=true"
```

**Windows (Command Prompt)**
```cmd
gh api ^
  --method PATCH ^
  -H "Accept: application/vnd.github+json" ^
  /repos/%REPO_OWNER%/%REPO_NAME% ^
  -F "allow_auto_merge=true" ^
  -F "delete_branch_on_merge=true"
```

> `delete_branch_on_merge=true` keeps the repo tidy by automatically removing
> Renovate's short-lived update branches after merge.

---

## 4 — Give GITHUB_TOKEN write permissions for auto-merge

The `auto-merge` CI job calls `gh pr merge`.  By default `GITHUB_TOKEN` only
has read access on pull requests.  Grant write access at the repo level:

**Linux / macOS**
```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO_OWNER}/${REPO_NAME}/actions/permissions/workflow" \
  -f "default_workflow_permissions=write" \
  -F "can_approve_pull_request_reviews=false"
```

**Windows (PowerShell)**
```powershell
gh api `
  --method PUT `
  -H "Accept: application/vnd.github+json" `
  "/repos/$REPO_OWNER/$REPO_NAME/actions/permissions/workflow" `
  -f "default_workflow_permissions=write" `
  -F "can_approve_pull_request_reviews=false"
```

**Windows (Command Prompt)**
```cmd
gh api ^
  --method PUT ^
  -H "Accept: application/vnd.github+json" ^
  /repos/%REPO_OWNER%/%REPO_NAME%/actions/permissions/workflow ^
  -f "default_workflow_permissions=write" ^
  -F "can_approve_pull_request_reviews=false"
```

---

## 5 — Verify the protection is active

**Linux / macOS**
```bash
gh api \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO_OWNER}/${REPO_NAME}/branches/${BRANCH}/protection" \
  | jq '{enforce_admins, required_status_checks, allow_force_pushes, allow_deletions}'
```

**Windows (PowerShell)**
```powershell
gh api `
  -H "Accept: application/vnd.github+json" `
  "/repos/$REPO_OWNER/$REPO_NAME/branches/$BRANCH/protection" | `
  ConvertFrom-Json | Select-Object enforce_admins, required_status_checks, allow_force_pushes, allow_deletions
```

**Windows (Command Prompt)** *(jq must be installed separately)*
```cmd
gh api ^
  -H "Accept: application/vnd.github+json" ^
  /repos/%REPO_OWNER%/%REPO_NAME%/branches/%BRANCH%/protection
```

---

## 6 — Install Renovate

Renovate is a GitHub App — it is not configured via `gh` CLI.

1. Go to https://github.com/apps/renovate
2. Click **Install** → select your account → choose **Only select repositories**
   → pick `chrome-devtools-mcp-canister`
3. Renovate will open an onboarding PR automatically.  Merge it to activate.

Once active, Renovate reads `.github/renovate.json` from your repo.

---

## Summary of what these commands enforce

| Setting | Value | Why |
|---|---|---|
| Required status checks | `build`, `MCP smoke test`, `Browser probe` | All three CI jobs must be green |
| Strict status checks | `true` | Branch must be up-to-date with `main` before merge |
| Enforce for admins | `true` | Applies the rule even to the sole maintainer |
| Force pushes | Blocked | Prevents rewriting `main` history |
| Branch deletions | Blocked | `main` cannot be accidentally deleted |
| Auto-merge | Enabled | Renovate PRs merge automatically when CI is green |
| Delete branch on merge | `true` | Renovate branches are cleaned up automatically |
| Workflow token permissions | `write` | `GITHUB_TOKEN` can call `gh pr merge` in CI |
