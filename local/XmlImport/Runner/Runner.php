<?php

namespace XmlImport\Runner;

use PDO;
use PDOException;
use XmlImport\Config\Config;

class Runner
{
    public $exitCode = 0;
    public $pdo;
    public $adapterInstances = [];

    public function __construct()
    {
    }

    public function start()
    {
        // establish database connection
        try {
            $this->pdo = new PDO(
                Config::get("database/conn"),
                Config::get("database/username"),
                Config::get("database/password")
            );
        } catch (PDOException $tEx) {
            // TODO send mail
            throw $tEx;
        }

        // load adapters
        $tAdapterConfigs = Config::get("adapters");

        foreach ($tAdapterConfigs as $tAdapterConfig) {
            $this->adapterInstances[] = new $tAdapterConfig["class"] ($this, $tAdapterConfig["config"]);
        }

        // download data
        foreach ($this->adapterInstances as $tAdapterInstance) {
            $tAdapterInstance->start();
        }
    }
}
