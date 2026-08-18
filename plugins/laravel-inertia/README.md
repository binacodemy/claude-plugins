# laravel-inertia

Classic Inertia: controllers render pages, domain data travels in props, and
the frontend has no separate JSON API to call. Built for codebases where
Inertia's page-per-controller model is the whole app, not a shell around a
mobile-ready API — for that shape, use `laravel-api` instead.

## Components

| Type | Name | Loads |
|---|---|---|
| Agent | `code-reviewer` | Proactively after code changes |
| Agent | `security-auditor` | Only when named (Opus) |
| Agent | `test-runner` | When verification is needed |
| Skill | `props-contract` | Automatically on `app/Data`, controllers, `HandleInertiaRequests`, `routes`, `resources/js` |
| Skill | `migrations` | Automatically on migrations, factories, models |
| Skill | `init` | You invoke it, once per project |
| Hook | `PostToolUse` | Formats the edited file; regenerates TypeScript when a Data class changes |
| Hook | `Stop` | Blocks finishing while Pint, PHPStan, tsc, ESLint, or the type-freshness check fails |

Both hooks exit immediately when there is no `./artisan`, so enabling this
globally is harmless.

## First run in a repo

```
/laravel-inertia:init
```

Generates `.claude/CLAUDE.md` from your real `composer.json`, `package.json`,
and `phpstan.neon`, then asks Claude to fill in the layout conventions. Write
the final line yourself — it is the correction you are tired of making in
review.

Then wire up `scaffold/authorization/` and run your test suite. An unguarded
controller action fails immediately. That is the point.

## Assumed dependencies

`inertiajs/inertia-laravel`. `spatie/laravel-data` and
`spatie/laravel-typescript-transformer` if you type your props (recommended,
not required) — `init` warns when one is present without the other.

## Don't enable both Laravel plugins on the same project

`laravel-api` and `laravel-inertia` ship a same-named
`code-reviewer` with contradictory rules — one enforces "no domain data in
props," the other enforces the opposite. Enable whichever matches how this
app actually moves data, never both at once.

## Permissions

`settings.json` at the plugin root supplies default permission rules on enable.
If your Claude Code version does not apply them, copy that block into the
project's `.claude/settings.json` — nothing else depends on it.
