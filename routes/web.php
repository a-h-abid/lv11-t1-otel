<?php

use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Route;
use OpenTelemetry\API\Trace\Span;

Route::get('/', function () {

    // Retrieve the current active span (ensure your OpenTelemetry middleware/tracer is set up)
    $span = Span::getCurrent();

    if ($span !== null && $span->getContext()->isValid()) {
        // Add the log as an event on the current span
        $span->addEvent('log', [
            'level'   => 'DEBUG',
            'message' => 'Yo yo',
            'context' => json_encode(['key' => 'value']),
        ]);
    }
    Log::info('Welcome page visited');
    return view('welcome');
});
