<?php

ignore_user_abort(true);
set_time_limit(0);

ini_set("display_errors", "on");
error_reporting(E_ALL);

date_default_timezone_set("Europe/Istanbul");

define("BASE_DIR", __DIR__ . "/../");

$tConfig = require __DIR__ . "/../config.php";

$tAutoLoader = require __DIR__ . "/../vendor/autoload.php";
$tAutoLoader->addPsr4("", __DIR__ . "/");

\XmlImport\Config\Config::set($tConfig);
