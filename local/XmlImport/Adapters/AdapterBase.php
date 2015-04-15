<?php

namespace XmlImport\Adapters;

use SimpleXMLElement;
use PO\QueryBuilder;
use XmlImport\Helpers\CurlHelper;
use XmlImport\Runner\Runner;

abstract class AdapterBase
{
    public $runner;
    public $id;
    public $url;
    public $outputFile;
    public $previousRemoteIdMap;
    public $previousChecksumMap;

    public function __construct(Runner $uRunner, $uConfig)
    {
        $this->runner = $uRunner;

        $this->id = $uConfig["id"];
        $this->url = $uConfig["url"];

        $this->outputFile = tempnam(sys_get_temp_dir(), "");
    }

    public function start()
    {
        $tFile = $this->download();
        if ($tFile === false) {
            // TODO throw error
            return false;
        }

        $this->loadPreviousMaps();
        $this->processFile($tFile);
    }

    public function download()
    {
        return CurlHelper::downloadFile($this->url);
    }

    public function loadPreviousMaps()
    {
        // TODO pull previous checksum => id pair by adapter id
        $tSelectQuery = QueryBuilder::factorySelect()
            ->select("Id, Checksum, RemoteId")
            ->from("Products")
            ->where("AdapterId", $this->id)
            ->toSql();

        $this->previousRemoteIdMap = [];
        $this->previousChecksumMap = [];

        $tRows = $this->runner->pdo->query($tSelectQuery);
        foreach ($tRows as $tRow) {
            $this->previousRemoteIdMap[$tRow['RemoteId']] = $tRow['Id'];
            $this->previousChecksumMap[$tRow['Id']] = $tRow['Checksum'];
        }

        var_dump($this->previousRemoteIdMap);
        var_dump($this->previousChecksumMap);
    }

    public function processFile($uFile)
    {
        $tXml = simplexml_load_file($uFile);
        // TODO throw error if it is not loaded
        return $this->processXml($tXml);
    }

    public abstract function processXml(SimpleXMLElement $uXml);

    protected function addLine($uValues)
    {
        // TODO calculate checksum of $uValues
        $tChecksum = 0;

        $tSql = "";

        if (isset($this->previousRemoteIdMap[$uValues["RemoteId"]])) {
            $tPreviousChecksum = $this->previousRemoteIdMap[$uValues["RemoteId"]];
            // update if the record has changed
            if ($tPreviousChecksum != $tChecksum) {
                // TODO update query
            }
        } else {
            // TODO insert query
        }

        file_put_contents($this->outputFile, "{$tSql}\n");
    }
}
