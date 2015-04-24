<?php

namespace XmlImport\Helpers;

use Exception;
use XmlImport\Config\Config;

class MailHelper
{
    public static function send($uTo, $uSubject, $uMessage)
    {
        $tHeaders = array(
            "From" => Config::get("mail/from"),
            "Reply-To" => Config::get("mail/from"),
            "Content-Type" => "text/html; charset=utf-8"
        );
        $tHeaders += Config::get("mail/headers");

        $tHeadersRaw = "";
        foreach ($tHeaders as $tHeaderKey => $tHeaderValue) {
            $tHeadersRaw += "{$tHeaderKey}: {$tHeaderValue}" . PHP_EOL;
        }

        mail($uTo, $uSubject, $uMessage, $tHeadersRaw);
    }

    public static function sendLog($uSubject, $uMessage)
    {
        static::send(Config::get("mail/to"), $uSubject, $uMessage);
    }

    public static function sendException(Exception $uException)
    {
        // for templating
        $exception = $uException;

        $tContent = require BASE_DIR . "etc/mailtemplate.php";

        static::sendLog("XmlImport Exception", $tContent);
    }
}
