<?php

namespace App\Logging\Formatter;

use Monolog\LogRecord;
use OpenTelemetry\API\Trace\Span;

class MyJsonFormatter extends \Monolog\Formatter\JsonFormatter
{
    public function format(LogRecord $record): string
    {
        $normalized = $this->normalizeRecord($record);
        unset($normalized['level'], $normalized['channel']);

        // Retrieve the current active span (ensure your OpenTelemetry middleware/tracer is set up)
        $span = Span::getCurrent();
        if ($span !== null && $span->getContext()->isValid()) {
            $this->sendToOtel($span, $normalized);

            // Add trace_id and span_id to regular log record
            $normalized['trace_id'] = $span->getContext()->getTraceId();
            $normalized['span_id'] = $span->getContext()->getSpanId();
        }

        if (!isset($normalized['context']) || empty($normalized['context'])) {
            $normalized['context'] = new \stdClass();
        }

        $normalized = ['source' => 'app'] + $normalized;

        return $this->toJson($normalized, true) . ($this->appendNewline ? "\n" : '');
    }

    private function sendToOtel(Span $span, array $normalized): void
    {
        // An exception event is already sent to OpenTelemetry, so we don't need to send it again
        if (isset($normalized['context']['exception'])) {
            return;
        }

        $span->addEvent('log.' . strtolower($normalized['level_name']), [
            'message' => $normalized['message'],
            'context' => json_encode($normalized['context'] ?? '{}'),
        ]);
    }
}
