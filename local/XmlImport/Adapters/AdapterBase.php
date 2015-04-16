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
    public $name;
    public $url;
    public $previousRemoteIdMap;
    public $previousChecksumMap;
    public $recordsAdded;
    public $recordsUpdated;
    public $recordsSkipped;
    public $downloads;

    public function __construct(Runner $uRunner, $uConfig)
    {
        $this->runner = $uRunner;

        $this->id = $uConfig["id"];
        $this->name = $uConfig["name"];
        $this->url = $uConfig["url"];
    }

    public function start()
    {
        echo "Adapter {$this->name} is starting..." . PHP_EOL;

        echo "- Downloading XML from {$this->url}" . PHP_EOL;
        $tFile = $this->downloadSource();
        if ($tFile === false) {
            // TODO throw error
            return false;
        }

        echo "- Resetting Status Values" . PHP_EOL;
        $this->recordsAdded = 0;
        $this->recordsUpdated = 0;
        $this->recordsSkipped = 0;
        $this->downloads = [];

        $this->resetStatuses();

        echo "- Processing Data" . PHP_EOL;
        $this->loadPreviousMaps();
        $this->processFile($tFile);
        echo "-- Completed: {$this->recordsAdded} added. {$this->recordsUpdated} updated. {$this->recordsSkipped} skipped." . PHP_EOL;

        echo "- Downloading Assets" . PHP_EOL;
        $this->downloadAssets();
        echo "-- Completed.";
    }

    public function downloadSource()
    {
        return CurlHelper::downloadFile($this->url);
    }

    public function downloadAssets()
    {
        foreach ($this->downloads as $tDownloadList) {
            foreach ($tDownloadList as $tDownload) {
                $tLocalFile = "{$tDownload["directory"]}/{$tDownload["file"]}";
                if (!is_dir($tDownload["directory"])) {
                    mkdir($tDownload["directory"], 0777, true);
                } else {
                    if (file_exists($tLocalFile)) {
                        continue;
                    }
                }

                echo "-- Downloading: {$tLocalFile}" . PHP_EOL;
                CurlHelper::downloadFile($tDownload["url"], $tLocalFile);
            }
        }
    }

    public function loadPreviousMaps()
    {
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
    }

    public function resetStatuses()
    {
        $tUpdateQuery = QueryBuilder::update()
            ->table("Products")
            ->set([
                "Status" => 0
            ])
            ->where("AdapterId", $this->id)
            ->toSql();

        $this->runner->pdo->exec($tUpdateQuery);
    }

    public function processFile($uFile)
    {
        $tXml = simplexml_load_file($uFile);
        // TODO throw error if it is not loaded
        return $this->processXml($tXml);
    }

    public abstract function processXml(SimpleXMLElement $uXml);

    protected function getLocalDownloadPaths($uAdapterId, $uCategory, $uUrls)
    {
        $tDirectory = "downloaded/{$uAdapterId}/{$uCategory}";
        $tLocalFiles = [];

        foreach ($uUrls as $tUrl) {
            $tLocalFiles[] = [
                "url" => $tUrl,
                "directory" => $tDirectory,
                "file" => str_replace(
                    "/",
                    "_",
                    parse_url($tUrl, PHP_URL_PATH)
                )
            ];
        }

        return $tLocalFiles;
    }

    protected function addDownloads($uLocalDownloads)
    {
        $this->downloads[] = $uLocalDownloads;
    }

    protected function addRecord($uValues, $uLocalDownloads = [])
    {
        $tSkipped = false;
        if (isset($this->previousRemoteIdMap[$uValues["RemoteId"]])) {
            $tPreviousId = $this->previousRemoteIdMap[$uValues["RemoteId"]];
            $tPreviousChecksum = $this->previousChecksumMap[$tPreviousId];

            // update if the record has changed
            if ($tPreviousChecksum != $uValues["Checksum"]) {
                $tUpdateQuery = QueryBuilder::update()
                    ->table("Products")
                    ->set($uValues)
                    ->where("Id", $tPreviousId)
                    ->limit(1)
                    ->toSql();

                $this->runner->pdo->exec($tUpdateQuery);

                $this->recordsUpdated++;
            } else {
                $this->recordsSkipped++;
                $tSkipped = true;
            }
        } else {
            $tInsertQuery = QueryBuilder::insert()
                ->into("Products")
                ->values($uValues)
                ->toSql();

            $this->runner->pdo->exec($tInsertQuery);
            $this->recordsAdded++;
        }

        if (!$tSkipped && $uValues["Status"] != 0) {
            $this->addDownloads($uLocalDownloads);
        }
    }
}
