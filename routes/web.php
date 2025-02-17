<?php

use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    Log::info('Welcome page visited', [
        'user' => 'John Wick',
    ]);

    return view('welcome');
});

Route::get('throwerr', function () {
    throw new \Exception("Error Processing Request", 1);

    return '';
});
