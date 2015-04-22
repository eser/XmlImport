<?php

namespace XmlImport\Helpers;

use Exception;

class MailHelper
{
    public static function send($uTo, $uSubject, $uMessage)
    {
        $tHeaders = "From: eser.ozvataf@zaimogluholding.com.tr" . PHP_EOL .
            "Reply-To: eser.ozvataf@zaimogluholding.com.tr" . PHP_EOL .
            "Content-Type: text/html; charset=utf-8" . PHP_EOL .
            "X-Mailer: PHP/" . phpversion();

        mail($uTo, $uSubject, $uMessage, $tHeaders);
    }

    public static function sendLog($uSubject, $uMessage)
    {
        static::send("it_eticaret@zaimogluholding.com.tr", $uSubject, $uMessage);
    }

    public static function sendException(Exception $uException)
    {
        static::sendLog("XmlImport Exception", $uException->getMessage());
    }
}
