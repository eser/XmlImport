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
            if (strlen($tHeadersRaw) > 0) {
                $tHeadersRaw .= PHP_EOL;
            }

            $tHeadersRaw .= "{$tHeaderKey}: {$tHeaderValue}";
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

        ob_start();
        require BASE_DIR . "etc/mailtemplate.php";
        $tContent = ob_get_clean();

        static::sendLog("XmlImport Error: " . get_class($uException), $tContent);
    }
}
