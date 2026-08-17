# binacode — Claude Code plugin marketplace

This repo is a plugin marketplace, not an application. Everything here is
configuration that shapes how Claude Code behaves in *other* repos.

## Structure

```
.claude-plugin/marketplace.json   catalog: every plugin must be listed here
plugins/<name>/
  .claude-plugin/plugin.json      manifest (name, version, description)
  agents/*.md                     subagents, frontmatter + system prompt
  skills/<name>/SKILL.md          skills; `paths:` makes them auto-load
  hooks/hooks.json                hook wiring, ${CLAUDE_PLUGIN_ROOT} paths
  bin/*                           scripts the hooks and skills call
  settings.json                   default settings applied on enable
  scaffold/                       reference files users copy into their app
```

## Current plugins

- **binacode-core** — stack-agnostic: `/commit`, `/pr`, `/upgrade-deps`,
  `debugger`. Enabled everywhere.
- **binacode-laravel-api** — API-first Laravel + Laravel Data + React Query.
  3 agents, 3 skills, 2 hooks, authorization scaffold.

Planned: `binacode-laravel-inertia` (classic Inertia, props carry data),
`binacode-react` (standalone React, no PHP).

## Rules for changing this repo

- **Shared components live in binacode-core, never duplicated.** Two stack
  plugins each shipping a `code-reviewer` means two competing descriptions
  when both are enabled.
- **One `code-reviewer` per stack plugin.** Adding a second reviewer-ish agent
  to the same plugin makes routing worse, not better.
- **Agent `description` is the routing signal.** Write trigger conditions, not
  a job title. If an agent isn't firing, sharpen the description before adding
  anything new.
- **Skills for procedures, agents for context isolation.** If the work needs
  back-and-forth or produces little output, it is a skill. Use `paths:` so it
  loads only when relevant.
- **Hooks must no-op outside their stack.** Every script starts by checking for
  a marker file (`artisan`) and exiting 0 if absent.
- **Exit 2 is the only blocking exit code.** Exit 1 is silently ignored.
- **Never add `hooks`, `mcpServers`, or `permissionMode` to a plugin agent's
  frontmatter** — ignored for security reasons.
- Update `marketplace.json` when adding a plugin. Bump the plugin `version`
  on any behavioral change.

## Testing a change

```
/plugin marketplace add ./binacode      # or `update` if already added
/plugin install <plugin>@binacode
```
Restart Claude Code, then `/plugin` (components + token cost), `/doctor`
(name collisions), `/hooks` (registration). Test in a real Laravel repo, not
here — the hooks look for `artisan`.

## Read DECISIONS.md before redesigning anything

It records why each choice was made and which parts are unverified. Several
obvious-looking "improvements" were tried and rejected for reasons that are
not visible from the code.
