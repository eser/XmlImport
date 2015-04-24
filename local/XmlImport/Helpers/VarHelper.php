<?php

namespace XmlImport\Helpers;

use SimpleXMLElement;

class VarHelper
{
    public static function toMysqlDate($tTimestamp)
    {
        return date("Y-m-d H:i:s", $tTimestamp);
    }

    public static function xmlArrayToJson(SimpleXMLElement $tIterator)
    {
        $tItems = array();
        foreach ($tIterator as $tItem)
        {
            $tItems[] = static::htmlDecode(current($tItem));
        }

        return $tItems;
    }

    public static function htmlDecode($uString)
    {
        $tDecoded = html_entity_decode($uString, ENT_COMPAT | ENT_HTML5, 'UTF-8');
        return html_entity_decode($tDecoded, ENT_COMPAT | ENT_HTML5, 'UTF-8');
    }

    public static function getFloat($uVar)
    {
        return (float)(str_replace(",", ".", $uVar));
    }
}
