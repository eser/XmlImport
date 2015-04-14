<?php

namespace XmlImport\Config;

class Config
{
    public static $raw;

    public static function set($uRaw)
    {
        static::$raw = $uRaw;
    }

    public static function get($uElement, $uDefault = null, $uSeparator = "/")
    {
        $tVariable = static::$raw;

        foreach (explode($uSeparator, $uElement) as $tKey) {
            if (!isset($tVariable[$tKey])) {
                return $uDefault;
            }

            $tVariable = $tVariable[$tKey];
        }

        return $tVariable;
    }
}
