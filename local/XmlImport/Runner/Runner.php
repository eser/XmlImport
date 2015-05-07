<?php

namespace XmlImport\Runner;

use Exception;
use PDO;
use PDOException;
use Monolog\Logger;
use Monolog\Handler\StreamHandler;
use XmlImport\Config\Config;
use XmlImport\Helpers\MailHelper;

class Runner
{
    public $exitCode = 0;
    public $logger;
    public $pdo;
    public $adapterInstances = array();

    public function __construct()
    {
    }

    public function start()
    {
        // create logger
        $tLogFile = BASE_DIR . "runner.log";

        $this->logger = new Logger("Runner");
        $this->logger->pushHandler(new StreamHandler($tLogFile, Logger::DEBUG));

        // establish database connection
        try {
            $this->pdo = new PDO(
                Config::get("database/conn"),
                Config::get("database/username"),
                Config::get("database/password")
            );

            $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

            $tCmds = Config::get("database/commands");
            if (strlen($tCmds) > 0) {
                $this->pdo->exec($tCmds);
            }
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
        $tJobs = array();
        $tStart = microtime(true);
        foreach ($this->adapterInstances as $tAdapterInstance) {
            $tLast = microtime(true);
            try {
                $tReturn = $tAdapterInstance->start();
                $tJobs[] = array($tAdapterInstance->name, "OK", microtime(true) - $tLast, $tReturn);
            } catch (Exception $tEx) {
                MailHelper::sendException($tEx);

                $tJobs[] = array($tAdapterInstance->name, "Failed", microtime(true) - $tLast, "");
                throw $tEx;
            }
        }

        // execute completed events
        $tCompleted = Config::get("events/completed");
        if (strlen($tCompleted) > 0) {
            $tLast = microtime(true);
            $tResult = shell_exec($tCompleted);
            $tJobs[] = array("event_completed", "OK", microtime(true) - $tLast, $tResult);
        }

        MailHelper::sendSummary($tJobs, microtime(true) - $tStart);
    }
}
