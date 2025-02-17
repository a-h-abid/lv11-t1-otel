<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(
            \OpenTelemetry\Contrib\Logs\Monolog\Handler::class,
            function () {
                return new \OpenTelemetry\Contrib\Logs\Monolog\Handler(
                    \OpenTelemetry\API\Globals::loggerProvider(),
                    \Monolog\Level::Info
                );
            }
        );
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
