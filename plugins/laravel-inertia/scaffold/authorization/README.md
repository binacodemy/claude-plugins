# Authorization guardrails — NOT wired up

Reference implementations. Copy into your app and adapt. Nothing here runs
until you do. Recommended order:

1. `EnsureRequestWasAuthorized.php` + the `Gate::after` snippet below — fails
   loudly in local/testing when a successful request performed no
   authorization check. Your existing test suite becomes the audit.
2. `ControllerRoutesAreGuardedTest.php` — catches a route missing `auth`
   middleware. It cannot catch a missing ownership check inside an otherwise
   authenticated controller action (`/teams/5/invitations/99` belonging to
   another team) — write that assertion per controller.
3. `scopeBindings()` on nested route groups — kills the nested-id IDOR class
   at the router, before the controller runs.

## AppServiceProvider::boot()

```php
Gate::after(function () {
    app()->instance('authz.checked', true);
    // return nothing — a non-null return would OVERRIDE the check result
});
```

Then register `EnsureRequestWasAuthorized` on your `web` middleware group.
Classic Inertia has one door to the data, the page controller, so that's the
group that matters here — the API plugin registers the same middleware on
`api` instead.

## Route groups

```php
Route::middleware('auth')->scopeBindings()->group(function () {
    Route::resource('teams.invitations', TeamInvitationController::class);
});
```

## Public pages

Give genuinely public routes an explicit name in the test's `$allowed` list,
so "no authorization here" is a written decision rather than an absence.
