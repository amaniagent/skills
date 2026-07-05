---
name: github-org-automation
description: Drive a GitHub organization from an agent with the gh CLI — create and manage org repos, PRs, issues and releases, manage teams and member permissions, trigger and watch Actions workflows, set org/repo secrets and branch-protection, all under least-privilege fine-grained tokens. Security-first on tokens: fine-grained PATs scoped to the minimum repos and permissions, never hardcoded, audited. Honest about where scopes and org policy limit what an automated agent can do. Use when scripting GitHub org management, automating repo/PR/release chores from an agent, wiring up Actions, or scoping a token safely for automation. Triggers include "gh CLI", "manage GitHub org", "create repo from agent", "trigger GitHub Actions", "org secrets", "branch protection", "fine-grained PAT scope".
---

# GitHub org automation — the gh CLI, safely

`gh` is the official GitHub CLI and the right tool for driving an org from an agent: it wraps the
REST/GraphQL API with sane commands, respects your auth, and is scriptable. The whole game is doing
this under a **least-privilege token** so an automated agent can't do more than the task needs.

> ⚠️ **Token first.** Use a **fine-grained PAT** scoped to the specific org, the specific repos, and
> the minimum permissions. Never hardcode it in scripts — read from env or a secret manager. A broad
> classic token in an autonomous agent is the thing that turns one bug into an org-wide incident.

## Auth & tokens

- `gh auth login` / `gh auth status` — interactive setup and check. For automation, set
  **`GH_TOKEN`** (or `GITHUB_TOKEN`) in the environment; `gh` picks it up without an interactive login.
- **Fine-grained PAT** > classic PAT: pick the resource owner (the org), select **only the repos**
  the job touches, and grant **only the permissions** needed (e.g. *Contents: read*, *Pull requests:
  write*) rather than blanket `repo` scope.
- Rotate and audit: review token scopes and usage via the org's audit log; short-lived tokens beat
  long-lived ones. In Actions, prefer the auto-provisioned `GITHUB_TOKEN` with a scoped `permissions:`
  block over a PAT.

## Repos, PRs, issues, releases

```bash
gh repo create ORG/name --private --clone         # org repo lives under the org namespace
gh repo list ORG --limit 100                       # inventory
gh pr create --base main --head feature --title T --body B
gh pr list / gh pr view N / gh pr merge N --squash
gh issue create / gh issue list --label bug
gh release create v1.2.0 --notes-file NOTES.md ./dist/*
```

Org repos are `ORG/repo`; user repos are `user/repo` — the namespace decides ownership and which
permissions apply.

## Teams & member permissions

- Manage access through **teams**, not one-off per-user grants — assign a team to a repo with a role
  and change it in one place.
- Repo roles, least→most: **read → triage → write → maintain → admin**. Give the lowest role that
  lets the work happen.
- Team/membership operations run via `gh api` (GraphQL/REST) — e.g.
  `gh api orgs/ORG/teams/TEAM/repos/ORG/REPO -X PUT -f permission=push`.

## Actions (CI)

```bash
gh workflow run deploy.yml -f env=staging      # manual dispatch (needs workflow_dispatch trigger)
gh run list --workflow deploy.yml
gh run watch                                    # follow the latest run to completion
gh run view RUN_ID --log
```

`workflow_dispatch` (and `repository_dispatch` for external triggers) is how you kick a workflow on
demand; event-driven triggers (`on: issues`, `on: pull_request`, labels) fire automatically.

## Secrets & branch protection

- Secrets: `gh secret set NAME --org ORG --visibility selected --repos "a,b"` (org level) or
  `gh secret set NAME --repo ORG/repo`. They're exposed to Actions, not readable back — set, never
  print.
- Branch protection (required reviews, required status checks, signed commits, linear history,
  no force-push): set via `gh api repos/ORG/REPO/branches/main/protection -X PUT ...` or repo
  rulesets. Validate rules on a **test repo/org** before applying org-wide.

## Verify

- After any change, **read it back**: `gh repo view`, `gh api .../protection`, `gh secret list`,
  `gh api orgs/ORG/teams/.../repos` — confirm the state matches intent, don't trust the write's exit
  code alone.
- Confirm the token has **exactly** the scopes used and no more (`gh auth status`, org token audit).
- Dry-run destructive or org-wide changes on a throwaway repo/org first.

## Honest limits

- **Org policy can override you**: SSO enforcement, IP allow-lists, required token approval, and
  member-privilege settings can block operations regardless of your token's scopes — the error will
  say so; that's policy, not a bug to route around.
- Fine-grained PATs don't cover **every** API surface yet; a few operations still need classic tokens
  or GitHub App auth — reach for a **GitHub App** (installation tokens) for serious, long-lived org
  automation over a personal PAT.
- Some team/enterprise operations need **owner/admin** rights; an agent with a scoped token simply
  can't perform them — surface that instead of escalating the token.
- This skill covers **driving** GitHub, not designing branching strategy, release process, or CI
  pipeline content — those are their own decisions.
