---
name: pr
description: Write a pull request description for the current branch and open the PR. Use when asked to raise, open, or describe a PR.
disable-model-invocation: true
allowed-tools: Bash(gh pr *) Bash(git log *) Bash(git diff *) Bash(git branch *)
argument-hint: [optional target branch]
---

## Branch context
- Branch: !`git branch --show-current || true`
- Commits: !`git log --oneline origin/HEAD..HEAD || true`
- Changed: !`git diff --stat origin/HEAD...HEAD || true`
- Template: !`cat .github/pull_request_template.md 2>/dev/null || echo none`

## Instructions

If a template exists above, follow it exactly. Otherwise:

**Summary** — 2–4 sentences for a reviewer with no ticket context.
**Changes** — bullets grouped by area, not a file listing.
**Testing** — what you ran; what a reviewer should check by hand.
**Risk** — migrations, env/config changes, breaking API changes, deploy steps.

Because this app is API-first, always call out explicitly:
- Any new or changed API endpoint, and how it is authorized.
- Any endpoint deliberately left public.
- Any change to an output Data class, which is a public contract change.

Read the diff; don't write the description from commit messages. Never claim
tests pass unless you ran them this session. Flag what a reviewer would push
back on rather than hiding it.

Show the draft first. Only run `gh pr create` after I approve. $ARGUMENTS
