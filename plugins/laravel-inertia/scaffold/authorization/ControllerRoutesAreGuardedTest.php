<?php

use Illuminate\Support\Facades\Route;

it('guards every page route with auth middleware', function () {
    // Reviewed exceptions only. Adding to this list is a security decision.
    $allowed = [
        'login', 'register', 'password.request', 'password.email',
        'password.reset', 'password.update',
        'verification.notice', 'verification.verify',
        'welcome',
    ];

    $unguarded = collect(Route::getRoutes())
        ->filter(fn ($r) => in_array('GET', $r->methods(), true))
        ->reject(fn ($r) => collect($r->gatherMiddleware())
            ->contains(fn ($m) => is_string($m) && ($m === 'auth' || str_starts_with($m, 'auth:'))))
        ->reject(fn ($r) => in_array($r->getName(), $allowed, true))
        ->map->uri()
        ->values();

    expect($unguarded)->toBeEmpty();

    // This only proves the route is authenticated. It says nothing about
    // whether the controller checks OWNERSHIP of a route-model-bound id —
    // that needs a per-controller test (see the plugin's security-auditor).
});
