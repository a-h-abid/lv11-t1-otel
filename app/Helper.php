<?php

namespace App;

class Helper
{
    public static function stdoutLog($message)
    {
        $handle = fopen('php://stdout', 'w');
        fwrite($handle, $message . PHP_EOL);
        fclose($handle);
    }
}
