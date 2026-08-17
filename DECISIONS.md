# Design decisions

Why things are the way they are. Read before redesigning — several of these
were tried the other way first.

## Architecture

**Core + stack plugins, not one big plugin.**
Plugin components are namespaced (`binacode-laravel-api:code-reviewer`) and
plugin scope is the *lowest* priority. They do not override same-named agents
from user or project scope — they coexist and compete for routing. So anything
stack-agnostic lives in `binacode-core` once, and stack plugins ship only what
is genuinely stack-specific. Enable core globally, stack plugins per project.

**Users must delete old user-level copies.**
An earlier iteration of this config shipped as shell installers writing to
`~/.claude/agents/` and `.claude/agents/`. Both outrank plugin scope, so a
leftover project-level `code-reviewer.md` silently shadows the plugin version
and it looks like the plugin is broken. The README says to remove them.

**`Explore` cannot be a plugin agent.**
Overriding the built-in `Explore` (e.g. to pin it to Haiku) only works from
user or project scope. Left out of the plugin deliberately.

**CLAUDE.md generation is a skill, not shipped config.**
A plugin cannot ship a project's CLAUDE.md. `skills/init` calls
`bin/init-project.php`, which detects versions from composer.json,
package.json, and phpstan.neon, then writes `.claude/CLAUDE.md` with the
layout conventions left as placeholders. It refuses to overwrite a file whose
Conventions section has been filled in. Better than the old installer version
because it is re-runnable after an upgrade.

## Agents vs skills

The criterion is **context isolation**, not topic.

- Subagent: work that floods context (test runs, wide greps) or benefits from
  a genuinely fresh reader (review). Returns a summary; the details stay in
  its own window.
- Skill: procedures that need to run *in* the main conversation, especially
  anything iterative. `paths:` scoping means it costs nothing until relevant.

**`db-migrator` was an agent and is now the `migrations` skill.** Writing a
migration produces almost no output and needs back-and-forth — both signs it
was the wrong shape. As a skill with `paths:`, the rules now apply during
normal implementation instead of requiring someone to remember to invoke it.

**`feature-implementer` with `isolation: worktree` was removed.** A fresh git
worktree has no `vendor/`, no `node_modules/`, no `.env`, and parallel agents
would share one database. Re-add only alongside real per-worktree DB setup.

**`security-auditor` is manual-invoke only** — its description says so
explicitly, which keeps it out of automatic routing. It runs on Opus and
overlaps with `code-reviewer` on routine diffs. `effort: high` was removed as
too expensive for per-change use; add it back in the prompt for a full audit.

## Hooks

**Two hooks, split by cost.** `PostToolUse` formats one file and always exits
0 — it must never interrupt. `Stop` runs the expensive checks and exits 2 to
push Claude back to work.

**Exit 2 is the only blocking code.** Exit 1 is silently ignored. This is the
most common hook bug; if a gate seems to do nothing, check this first.

**The Stop hook is scoped to changed files.** Full-repo PHPStan on a large app
takes 30–60s and would run every time Claude finishes a turn. Scoped analysis
misses cross-file errors elsewhere — that is what `@test-runner` is for.

**`stop_hook_active` guard is mandatory.** Without it, a gate that keeps
failing traps Claude in an infinite stop loop.

**Scripts parse stdin JSON with `php -r`, not `jq`.** PHP is guaranteed
present in a Laravel project; `jq` is not.

**Type regeneration is the point of the PostToolUse hook.** Editing anything
in `app/Data/` triggers `php artisan typescript:transform`, so the frontend
never sees a stale contract. The Stop hook re-runs it and fails if that
produced a diff. This makes type drift structurally impossible rather than a
rule someone follows.

## The API-first content

**Endpoint authorization is the top risk and is treated as such.** Two doors
exist to the same data (Inertia page controller, API endpoint) and only the
API one matters, because a mobile client never opens the first. It appears in
four places on purpose: the auditor starts there, the reviewer checks it
first, `api-contract` states it as a hard rule, and `scaffold/authorization/`
provides a runtime tripwire plus a route-coverage test.

**`#[Hidden]` is not a security control.** It excludes a property from the
generated TypeScript, not from the JSON payload. Called out in both the
reviewer and auditor prompts because it reads like a guarantee and is not.

**Permission flags per row are an N+1 no eager load fixes.** `Gate::allows()`
inside a Data object on a paginated collection means one policy call per row.

**Agent teams stay off.** With teams enabled, any *named* subagent launches as
a teammate instead, which changes how results come back. The workflow this
plugin encodes is sequential, so teams add cost without benefit. Parallel
read-only review of a large diff is the one genuine fit.

## Unverified — check before relying on

These were written from secondary sources, not the official reference:

1. **`settings.json` at the plugin root supplying default permissions on
   enable.** If permissions do not apply, copy the block into the project's
   `.claude/settings.json`. Nothing else depends on it.
2. **`hooks/hooks.json` schema and `${CLAUDE_PLUGIN_ROOT}` substitution.**
   Verify with `/hooks` in a real Laravel project. Fallback is the same block
   in project settings with `$CLAUDE_PROJECT_DIR`.
3. **`marketplace.json` schema.** If `/plugin marketplace add` complains, check
   the plugins reference; the fix should be small.
4. **`bin/init-project.php` has never been executed** — written in an
   environment without PHP. Lint it with `php -l` before first use.
5. The optional `type: "agent"` Stop hook documented in the laravel-api
   plugin's hooks README is experimental.

## Roadmap

**binacode-laravel-inertia** — classic Inertia where props carry domain data.
Start from `binacode-laravel-api/agents/code-reviewer.md`, strip the API and
React Query sections, restore prop-leakage and deferred-props material. Keep
`migrations` (identical). Drop `api-contract`, replace with a props-contract
skill. Hooks can be reused as-is.

**binacode-react** — standalone React. No PHP, so `bin/*.sh` need a different
marker file (`package.json` plus absence of `artisan`) and the transform step
drops out entirely.

**Worth doing regardless:**
- Prune after real use. Any agent not invoked in a month should go.
- Bump plugin `version` on behavioral changes so rollout is deliberate.
- Consider `skill-creator` evals to measure whether a skill actually improves
  outcomes rather than assuming it does.
- Watch `/plugin` token cost per session as skills accumulate.
