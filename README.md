# binacode

Claude Code plugins for Binacode projects. One marketplace, one plugin per
stack, plus a shared core.

## Install

```
/plugin marketplace add binacode/claude-plugins        # or ./binacode locally
/plugin install core@binacode
/plugin install laravel-api@binacode        # or laravel-inertia@binacode — not both
```

Per project instead of globally:

```
claude plugin install laravel-api@binacode --scope project
```

## Plugins

| Plugin | For | Ships |
|---|---|---|
| `core` | Everything | `/commit`, `/pr`, `/upgrade-deps`, `debugger` agent |
| `laravel-api` | API-first Laravel + Laravel Data + React Query | 3 agents, `api-contract` + `migrations` + `init` skills, format and quality-gate hooks, authorization scaffold |
| `laravel-inertia` | Classic Inertia, props carry domain data, no separate JSON API | 3 agents, `props-contract` + `migrations` + `init` skills, format and quality-gate hooks, authorization scaffold |
| `react` | *planned* — standalone React apps | frontend agents and hooks, no PHP |

`core` is designed to be enabled everywhere. Everything stack-specific
lives in exactly one stack plugin.

## Enable one stack plugin per project

Stack plugins each ship a `code-reviewer`. Enabling two in the same project
gives you two reviewers competing for the same routing, and Claude has to guess
which one you meant. Install stack plugins with `--scope project`, or keep one
enabled globally if you only work in one stack. In particular, `laravel-api`
and `laravel-inertia` are mutually exclusive — never enable both on the same
project.

Component names are namespaced by plugin: `@laravel-api:code-reviewer`,
`/core:commit`. The bare `/commit` also resolves unless another
command already uses that name.

## If you previously used the shell installers

Delete the user-level copies, or they will coexist and compete with the plugin
versions — plugin agents do not override same-named user agents:

```
rm ~/.claude/agents/{code-reviewer,security-auditor,test-runner,debugger}.md
rm -rf ~/.claude/skills/{commit,pr,upgrade-deps}
```

Keep `~/.claude/agents/Explore.md` if you use it. An `Explore` override must be
a user or project agent to replace the built-in — a plugin cannot do it.

Project `.claude/agents/` and `.claude/skills/` from the old installer should
also be removed, since project scope outranks plugin scope and would shadow
the plugin entirely.

## Adding a stack plugin

Copy `plugins/laravel-api` as a starting point, rename it, and add an
entry to `.claude-plugin/marketplace.json`. Keep shared workflow skills in
`core` rather than duplicating them — that is the whole reason core
exists.
