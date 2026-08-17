<?php

use Illuminate\Support\Facades\Route;

it('guards every api route', function () {
    // Reviewed exceptions only. Adding to this list is a security decision.
    $allowed = [
        'api.health',
        // 'api.webhooks.stripe',
    ];

    $unguarded = collect(Route::getRoutes())
        ->filter(fn ($r) => str_starts_with($r->uri(), 'api/'))
        ->reject(fn ($r) => collect($r->gatherMiddleware())
            ->contains(fn ($m) => is_string($m) && str_contains($m, 'auth')))
        ->reject(fn ($r) => in_array($r->getName(), $allowed, true))
        ->map->uri()
        ->values();

    expect($unguarded)->toBeEmpty();
});
