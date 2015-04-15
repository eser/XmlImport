<?php

namespace XmlImport\Adapters;

use XmlImport\Helpers\CurlHelper;

abstract class AdapterBase
{
    public $url;

    public function __construct($uConfig)
    {
        $this->url = $uConfig["url"];
    }

    public function download()
    {
        $tFile = CurlHelper::downloadFile($this->url);
        echo $tFile;
    }
}
