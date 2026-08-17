<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

/**
 * Fails loudly when a successful request performed no authorization check.
 * Throws in local/testing so the test suite catches it; logs in production
 * so customers are never the ones who find out.
 */
class EnsureRequestWasAuthorized
{
    public function handle(Request $request, Closure $next)
    {
        app()->forgetInstance('authz.checked');

        $response = $next($request);

        if (! app()->bound('authz.checked') && $response->isSuccessful()) {
            $message = sprintf(
                'No authorization check ran for %s /%s',
                $request->method(),
                $request->path()
            );

            if (app()->environment('local', 'testing')) {
                throw new \LogicException($message);
            }

            Log::critical($message, ['user' => $request->user()?->id]);
        }

        return $response;
    }
}
