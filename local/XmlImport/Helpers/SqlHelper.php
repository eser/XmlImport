<?php

namespace XmlImport\Helpers;

class SqlHelper
{
    public static function splitSqlFile($uFile, $uDelimiter = ";")
    {
        $tFile = fopen($uFile, "r");

        $tQueries = array();
        $tBuffer = array();

        while (!feof($tFile))
        {
            $tBuffer[] = fgets($tFile);

            if (preg_match("~" . preg_quote($uDelimiter, "~") . "\\s*$~iS", end($tBuffer)) === 1)
            {
                $tQueries[] = implode("", $tBuffer);
                $tBuffer = array();
            }
        }

        fclose($tFile);

        return $tQueries;
    }

    public static function getUsedParameters($uSqlString, $uParameters)
    {
        $tFound = array();

        foreach ($uParameters as $tKey => $tValue) {
            if (stripos($uSqlString, $tKey) > -1)
            {
                $tFound[$tKey] = $tValue;
            }
        }

        return $tFound;
    }
}
