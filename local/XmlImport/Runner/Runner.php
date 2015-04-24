<?php

namespace XmlImport\Runner;

use Exception;
use PDO;
use PDOException;
use XmlImport\Config\Config;
use XmlImport\Helpers\MailHelper;

class Runner
{
    public $exitCode = 0;
    public $pdo;
    public $adapterInstances = array();

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

            $this->pdo->exec("SET NAMES 'utf8'");
        } catch (PDOException $tEx) {
            MailHelper::sendException($tEx);
            throw $tEx;
        }

        // load adapters
        $tAdapterConfigs = Config::get("adapters");

        foreach ($tAdapterConfigs as $tAdapterConfig) {
            $this->adapterInstances[] = new $tAdapterConfig["class"] ($this, $tAdapterConfig["config"]);
        }

        // download data
        foreach ($this->adapterInstances as $tAdapterInstance) {
            try {
                $tAdapterInstance->start();
            } catch (Exception $tEx) {
                MailHelper::sendException($tEx);
                throw $tEx;
            }
        }
    }
}
