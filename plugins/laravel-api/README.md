# laravel-api

API-first Laravel: Laravel Data objects, JSON API endpoints, Inertia as a page
shell only, React Query on the frontend. Built for codebases where a second
client (mobile, another frontend) is a real plan — the rules exist to keep
endpoints usable by a client that never loads a page.

## Components

| Type | Name | Loads |
|---|---|---|
| Agent | `code-reviewer` | Proactively after code changes |
| Agent | `security-auditor` | Only when named (Opus) |
| Agent | `test-runner` | When verification is needed |
| Skill | `api-contract` | Automatically on `app/Data`, `app/Http`, `app/Queries`, `routes`, `resources/js` |
| Skill | `migrations` | Automatically on migrations, factories, models |
| Skill | `init` | You invoke it, once per project |
| Hook | `PostToolUse` | Formats the edited file; regenerates TypeScript when a Data class changes |
| Hook | `Stop` | Blocks finishing while Pint, PHPStan, tsc, ESLint, or the type-freshness check fails |

Both hooks exit immediately when there is no `./artisan`, so enabling this
globally is harmless.

## First run in a repo

```
/laravel-api:init
```

Generates `.claude/CLAUDE.md` from your real `composer.json`, `package.json`,
and `phpstan.neon`, then asks Claude to fill in the layout conventions. Write
the final line yourself — it is the correction you are tired of making in
review.

Then wire up `scaffold/authorization/` and run your test suite. Unguarded
endpoints fail immediately. That is the point.

## Assumed dependencies

`spatie/laravel-data`, `spatie/laravel-typescript-transformer`,
`@tanstack/react-query`. `init` warns for any that are missing.

## Permissions

`settings.json` at the plugin root supplies default permission rules on enable.
If your Claude Code version does not apply them, copy that block into the
project's `.claude/settings.json` — nothing else depends on it.
