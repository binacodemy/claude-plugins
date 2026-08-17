---
name: props-contract
description: Rules for what Inertia props may carry, page-controller authorization, Laravel Data objects, deferred/lazy props, and forms. Applies when implementing or changing anything that reaches Inertia::render() or a shared prop.
paths: app/Data/**, app/Http/Controllers/**, app/Http/Middleware/HandleInertiaRequests.php, routes/**, resources/js/**
---

This app is classic Inertia: controllers render pages and domain data travels
in props. There is no separate JSON API and no React Query layer — the props
a controller builds ARE the contract with the frontend.

## Authorization — the hard rule
Every controller action that touches a model performs an explicit
authorization check before building its props. Route `auth` middleware alone
does not verify ownership of a nested id.

Verify ownership of every route-model-bound id, not only the last one. Prefer
`scopeBindings()` on the route group so `/teams/5/invitations/99` 404s when 99
belongs to another team, before the controller runs.

A page that genuinely needs no check goes in the public allowlist and gets
called out in the PR description. Silence is not a decision.

## What a prop may contain
Everything passed to `Inertia::render()` ships in the initial page response
and in every partial reload (`only=`/`except=`), whether or not the current
UI renders it. Build props from what the page needs, not from what is
convenient to grab in the controller.

- Prefer a Data object or Resource over an inline array once a shape is used
  from more than one action.
- Permission flags are computed from the policy inside the Data class
  (`can_resend: Gate::allows('resend', $invitation)`), never re-derived
  client-side from dates or status.
- Enums over string fields, so the generated type is a real union.
- Never hand-edit a generated type file. Change the Data class; the
  PostToolUse hook regenerates.

## Deferred and lazy props
- `Inertia::lazy()` for data only needed on a partial reload; `Inertia::defer()`
  for data that should load after the initial render. Neither is a security
  boundary — the same authorization check must run when the closure actually
  executes, not only on first render.
- `Inertia::merge()` only for genuinely append-only props (infinite scroll,
  activity feed). A prop that can shrink or replace must not merge, or the
  client keeps stale rows.
- A prop closure that queries per row (a `Gate::allows()` or relation load
  inside `->map()`) is an N+1 no eager load upstream fixes. Eager-load before
  building the prop.

## Shared data (HandleInertiaRequests)
Runs on every request including partial reloads, so keep it to: authenticated
identity and permissions, flash from genuine redirect flows, and feature
flags. Domain data belongs in a page-specific prop, not shared data, however
convenient it looks for one page.

No sensitive field on the shared `auth.user` — it round-trips on every
navigation.

## Forms
- Client uses `useForm()`. Server validates with a FormRequest; a
  `ValidationException` flows back through Inertia's shared `errors` prop
  automatically. Do not hand-roll a 422 body — this isn't the API plugin.
- Flash messages come from genuine redirect flows only (post-redirect-get),
  never attached to the initial render of the page that triggered them.
- File uploads: spoof the method with `_method` on a POST, never issue a real
  PUT/PATCH with a multipart body — method spoofing doesn't survive the other
  direction.

## Queries
- **Scopes**: small, reusable, composable constraints about the model's own
  data. Use from day one.
- **Query objects** (`app/Queries`): composing filters, sorts, eager loads,
  and pagination for a page. Write one at the second caller, not the first —
  a query object for a single-caller page is ceremony.
- **Actions**: writes and side effects only.
- Eager loading belongs in the query object, feeding the props — not
  scattered through controllers.
