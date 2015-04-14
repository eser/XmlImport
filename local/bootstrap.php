<?php

$tConfig = require __DIR__ . "/../config.php";

$tAutoLoader = require __DIR__ . "/../vendor/autoload.php";
$tAutoLoader->addPsr4("", __DIR__ . "/");

\XmlImport\Config\Config::set($tConfig);
