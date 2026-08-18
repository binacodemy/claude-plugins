---
name: upgrade-deps
description: Audit and upgrade project dependencies safely, one risk tier at a time. Use when asked to update packages, bump versions, or fix a security advisory.
disable-model-invocation: true
allowed-tools: Bash(composer outdated *) Bash(composer audit *) Bash(npm outdated *) Bash(npm audit *) Bash(git status *)
argument-hint: [optional package name]
---

## Current state
```!
test -f composer.json && composer outdated --direct 2>/dev/null || echo "no composer.json"
test -f package.json && npm outdated 2>/dev/null || echo "no package.json"
```

## Instructions

Never upgrade everything at once. Work in tiers, committing between each so a
regression is bisectable:

1. **Security first** — `composer audit`, `npm audit`. Advisories get fixed
   before anything else, on their own commit.
2. **Patch and minor** for direct dependencies. Batch, verify, commit once.
3. **Majors, one at a time.** Read the upgrade guide first, list the breaking
   changes that actually affect this codebase, then apply.

Rules: direct dependencies only, never hand-edit a lockfile, and treat a
framework major as a project to report on rather than start unprompted. Run the
full check suite after each tier; fix or roll back before moving on.

A `spatie/laravel-data` or typescript-transformer upgrade needs
`php artisan typescript:transform` re-run and the generated diff reviewed —
a minor bump there can change every generated type.

Report what moved, what you skipped and why, and anything still blocking a
security advisory. If given a package name, scope all of this to it. $ARGUMENTS
