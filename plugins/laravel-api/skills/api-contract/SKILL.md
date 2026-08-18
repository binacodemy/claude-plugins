---
name: api-contract
description: Rules for the API-first boundary — endpoint authorization, Laravel Data objects, query building, what Inertia may carry, and how React Query consumes it. Applies when implementing or changing anything crossing that boundary.
paths: app/Data/**, app/Http/**, app/Queries/**, app/Actions/**, routes/**, resources/js/**
---

This app is API-first. Inertia renders the page shell and shares session
state. All domain data is fetched from the JSON API by React Query. A second
client (mobile) is planned, so no endpoint may assume a browser.

## Authorization — the hard rule
Every API controller method performs an explicit authorization check. Never
assume the caller loaded a page first; a mobile client never will. The page
controller authorizes viewing the page and nothing else.

Verify ownership of every id in the path, not only the last one. Prefer
`scopeBindings()` on the route group so `/api/teams/5/invitations/99` 404s
when 99 belongs to another team, before the controller runs.

An endpoint that genuinely needs no check goes in the public allowlist and
gets called out in the PR description. Silence is not a decision.

## Laravel Data
- Separate classes per direction: `CreateInvitationData` for input,
  `InvitationData` for output. Only output classes carry `#[TypeScript]`.
- If a field must never reach a client, it is not a property on the class.
  `#[Hidden]` controls generated TypeScript, not the payload.
- Permission flags are computed from the policy inside the Data class
  (`can_resend: Gate::allows('resend', $invitation)`), never re-derived
  client-side from dates or status.
- Enums over string fields, so the generated type is a real union.
- Carbon and paginator types are handled by the transformer — do not
  hand-write those TypeScript shapes.
- Never hand-edit a generated type file. Change the Data class; the
  PostToolUse hook regenerates.
- After creating or changing a Data class, show the class and the regenerated
  TypeScript together, and stop for review before building anything on top
  of that shape.

## API endpoints
- Return a Data object, never a raw model or `toArray()`.
- Paginate every collection.
- Stay client-agnostic: no field exists because the current page wants it.
- Multi-write in `DB::transaction()`; mail, jobs, and webhooks after commit.

## Query building
- **Scopes**: small, reusable, composable constraints about the model's own
  data. Use from day one.
- **Query objects** (`app/Queries`): composing filters, sorts, eager loads,
  and pagination for an endpoint. Write one at the second caller, not the
  first — a query object for a single-caller endpoint is ceremony.
- **Actions**: writes and side effects only. A `GetSomethingAction` next to a
  `CreateSomethingAction` means "action" has stopped meaning anything.
- Eager loading belongs in the query object, not scattered through callers.
- **Data objects shape, they never fetch.** If building a Data object triggers
  a query, the eager load is missing upstream.
- Permission flags on a collection: a `Gate::allows()` per row is an N+1 that
  no eager load fixes. Compute once per page where the answer doesn't vary, or
  ensure the policy only reads already-loaded relations.

## What Inertia props may contain — the whole list
Authenticated identity and permissions, route parameters the page needs to
build its queries, feature flags choosing the shell, and flash from genuine
redirect flows only (OAuth callback, email verification, post-login).

Validation errors do NOT come through the `errors` prop here — an XHR mutation
returns 422 with its own error body. Do not reach for `useForm`.

Domain data in props is an architecture violation regardless of size.

## React Query
- One hook per endpoint in resources/js/api/. No bare fetch in a component.
- Structured query keys (['team', teamId, 'invitations']) so invalidation is precise.
- Mutations invalidate the keys they affect.
- Every query handles loading and error. Rendering nothing on error is a bug.
- Map 422 field errors back into the form.
- Never derive an authorization decision on the client. Ask the API.
- If the API does not provide what the UI needs, STOP and say what is missing.
  Never work around it in a component.
