<?php

namespace XmlImport\Adapters;

abstract class AdapterBase
{
    public $url;

    public function __construct($uConfig)
    {
        $this->url = $uConfig["url"];
    }

    public function download()
    {
        echo $this->url;
    }
}
