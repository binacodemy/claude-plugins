---
name: commit
description: Stage and commit current changes with a well-formed message. Use when asked to commit, or to split work into logical commits.
disable-model-invocation: true
allowed-tools: Bash(git add *) Bash(git commit *) Bash(git status *) Bash(git diff *) Bash(git log *)
argument-hint: [optional scope or instruction]
---

## Working tree
- Staged: !`git diff --staged --stat || true`
- Unstaged: !`git diff --stat || true`
- Untracked: !`git ls-files --others --exclude-standard || true`
- Recent messages (match this style): !`git log --oneline -15 || true`

## Instructions

Read the real diff before writing anything.

1. If the changes cover more than one concern, propose splitting them into
   separate commits. Don't silently bundle unrelated work.
2. Match the message style in the log above. Don't impose conventional commits
   on a repo that doesn't use them.
3. Subject: imperative, under 72 chars, no trailing period. Body only when the
   *why* isn't obvious from the diff.
4. Never commit `.env`, credentials, debug statements added for local work
   (`dd()`, `dump()`, `console.log`), commented-out code, or `.orig` files.
   Stop and flag these instead.
5. A generated TypeScript file belongs in the same commit as the Data class
   that produced it.
6. Never `git add -A` without first listing what it would include.

Show the proposed message and exact file list, then wait for confirmation
before running `git commit`. $ARGUMENTS
