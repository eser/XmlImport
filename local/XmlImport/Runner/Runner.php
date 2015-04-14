<?php

namespace XmlImport\Runner;

use XmlImport\Config\Config;

class Runner
{
    public $exitCode = 0;
    public $adapterInstances = [];

    public function __construct()
    {

    }

    public function start()
    {
        // load adapters
        $tAdapterConfigs = Config::get("adapters");

        foreach ($tAdapterConfigs as $tAdapterConfig) {
            $this->adapterInstances[] = new $tAdapterConfig["class"] ($tAdapterConfig["config"]);
        }

        // download data
        foreach ($this->adapterInstances as $tAdapterInstance) {
            $tAdapterInstance->download();
        }
    }
}
