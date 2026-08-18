# Authorization guardrails — NOT wired up

Reference implementations. Copy into your app and adapt. Nothing here runs
until you do. Recommended order:

1. `EnsureRequestWasAuthorized.php` + the `Gate::after` snippet below — fails
   loudly in local/testing when a successful request performed no
   authorization check. Your existing test suite becomes the audit.
2. `ApiRoutesAreGuardedTest.php` — catches routes no test exercises.
3. `scopeBindings()` on your API route groups — kills the nested-id IDOR class
   at the router.

## AppServiceProvider::boot()

```php
Gate::after(function () {
    app()->instance('authz.checked', true);
    // return nothing — a non-null return would OVERRIDE the check result
});
```

Then register `EnsureRequestWasAuthorized` on your `api` middleware group.

## Route groups

```php
Route::middleware('auth:sanctum')->scopeBindings()->group(function () {
    Route::apiResource('teams.invitations', TeamInvitationController::class);
});
```

## Public endpoints

Give genuinely public routes an explicit `public-endpoint` middleware that
sets the flag, so "no authorization here" is a written decision rather than
an absence.
