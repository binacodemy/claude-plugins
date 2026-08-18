# Design decisions

Why things are the way they are. Read before redesigning — several of these
were tried the other way first.

## Architecture

**Core + stack plugins, not one big plugin.**
Plugin components are namespaced (`laravel-api:code-reviewer`) and
plugin scope is the *lowest* priority. They do not override same-named agents
from user or project scope — they coexist and compete for routing. So anything
stack-agnostic lives in `core` once, and stack plugins ship only what
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

**PHPStan's scope is changed files *intersected with* `phpstan.neon`'s
`paths:`.** Paths passed on the PHPStan CLI override `parameters.paths` in the
config, so blindly handing it every changed `.php` file analyses code the
project never configured for analysis — `tests/` is the usual victim, since a
stock Larastan config only lists `app/`, and the resulting errors have no
baseline and can't be fixed from within scope. `quality-gate.sh` reads
`phpstan.neon`'s `paths:` itself and filters to that (defaulting to `app/` if
no config or no `paths:` key is found) rather than editing the user's
`phpstan.neon` to add `tests/` — widening the project's own analysis surface
is not this hook's call to make, and doing so would surface that same wall of
pre-existing errors immediately.

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

## The Inertia-props content

**laravel-inertia is built.** Forked from
`laravel-api/agents/code-reviewer.md` per the original roadmap
entry: stripped the API-endpoint and React Query sections, kept the
Laravel-Data material (props are commonly Data-object-shaped even without a
JSON API), and wrote prop-leakage and deferred/lazy-prop material fresh —
there was no prior version to restore it from, despite how the original plan
note read.

**"Two doors" becomes "one door."** The API plugin's authorization framing
(page controller vs. API endpoint, only the second matters) doesn't apply
here — there is one controller and it always runs. Re-centered on: everything
in a prop ships to the client regardless of what the UI renders (the same
trust-boundary shift `#[Hidden]` gets flagged for in the API plugin), and a
`lazy`/`defer` prop closure must still run its authorization check when
evaluated, not just on initial render.

**`api-contract` became `props-contract`, not a rename.** The hard rule
inverts: the API plugin's skill forbids domain data in Inertia props, this
one's skill exists because domain data in props is correct here. Keeping one
skill and parameterizing it would have made the file self-contradictory.

**Hooks, `migrations`, `settings.json`, and `EnsureRequestWasAuthorized.php`
were reused byte-for-byte.** None of them reference the API/React Query
split — the Stop-hook quality gate, the migration rules, and the "no
successful response without an authorization check" middleware are true
regardless of how props reach the client. Only the route-coverage test and
its README changed, because the API version filters routes by an `api/`
prefix that doesn't exist in a classic Inertia app; the replacement checks
for `auth` middleware on every GET route instead and says plainly that it
cannot catch a missing ownership check inside an authenticated action.

**Unverified like the rest of this plugin's family:** `init-project.php` has
not been run against a real Inertia project.

**Building it surfaced three bugs that were already live in
laravel-api, fixed in both at once (0.1.0 → 0.1.1 for the API
plugin) rather than only in the new copy:**
1. `init-project.php`'s overwrite guard checked for a label string
   (`'The one thing a new developer'`) present in every generated file
   whether or not it was filled in, so it never actually refused to
   overwrite a hand-edited `CLAUDE.md`. Fixed to check for `'...>'` instead —
   every unfilled Conventions placeholder is wrapped in `<... | ...>`, so
   that substring's absence is what "a human filled this in" actually means.
2. `quality-gate.sh`'s `CHANGED` list came only from `git diff` and
   `git diff --cached`, so a new file that was never `git add`ed — the
   normal state right after `Write` — was invisible to the gate, including
   the type-freshness check. Added `git ls-files --others --exclude-standard`
   to the union.
3. Both route-coverage tests rejected a route as "guarded" on
   `str_contains($middleware, 'auth')`, which a middleware alias like
   `author` (checks post authorship, not login) would false-positive.
   Tightened to an exact match on `auth` or a `auth:` prefix.

Chose to fix both plugins rather than the new one only, specifically because
the five files above are otherwise kept byte-identical on purpose — patching
one copy and not the other would have created drift immediately.

**Considered moving those five identical files into core, decided
not to yet.** Nothing in `quality-gate.sh`, `format-file.sh`, `settings.json`,
`EnsureRequestWasAuthorized.php`, or `migrations/SKILL.md` is API- or
Inertia-specific, so `core` is where they arguably belong per this
file's own "shared components live in core, never duplicated" rule.
Left them duplicated for now because there's only one real consumer of the
duplication risk today (these two plugins are never both enabled on the same
project — see the mutual-exclusion note in each README) — revisit when
`react` needs the same files and a third copy would otherwise
appear, per "prune after real use" below.

## Naming

**Plugins dropped the `binacode-` prefix (`binacode-laravel-api` →
`laravel-api`, etc.), version 0.1.x → 0.2.0 across all three.** Claude Code
namespaces every plugin agent as `<plugin-name>:<agent-name>` in the
@-mention picker — this is fixed, not configurable via agent frontmatter or
`plugin.json` (confirmed against the Claude Code docs before making this
change). With the old names that produced
`@"binacode-laravel-api:code-reviewer (agent)"`, which is what the plugin
name directly controls, so the plugin name is where the fix has to live —
the marketplace's own `name: "binacode"` stays as-is since it doesn't feed
the agent-mention prefix. Users on the old names must reinstall
(`/plugin marketplace update`, then reinstall each plugin under its new
name) — same-repo-source reinstall, no data migration involved.

## Roadmap

**react** — standalone React. No PHP, so `bin/*.sh` need a different
marker file (`package.json` plus absence of `artisan`) and the transform step
drops out entirely.

**Worth doing regardless:**
- Prune after real use. Any agent not invoked in a month should go.
- Bump plugin `version` on behavioral changes so rollout is deliberate.
- Consider `skill-creator` evals to measure whether a skill actually improves
  outcomes rather than assuming it does.
- Watch `/plugin` token cost per session as skills accumulate.
