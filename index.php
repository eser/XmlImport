<?php

require __DIR__ . "/local/bootstrap.php";

$tRunner = new \XmlImport\Runner\Runner();
$tRunner->start();

exit($tRunner->exitCode);
