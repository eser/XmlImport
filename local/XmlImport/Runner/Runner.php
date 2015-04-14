<?php

namespace XmlImport\Runner;

use XmlImport\Config\Config;

class Runner
{
    public $exitCode = 0;

    public function __construct()
    {

    }

    public function start()
    {
        echo Config::get("database/host");
    }
}
