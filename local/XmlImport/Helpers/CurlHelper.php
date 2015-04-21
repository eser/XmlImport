<?php

namespace XmlImport\Helpers;

class CurlHelper
{
    public static function downloadFile($uUrl, $uFile = null)
    {
        if ($uFile === null) {
            $uFile = tempnam(sys_get_temp_dir(), "");
        }

        $tFilePointer = fopen($uFile, "w+");

        $tCurl = curl_init();
        curl_setopt_array(
            $tCurl,
            [
                CURLOPT_URL => $uUrl,
                CURLOPT_TIMEOUT => 50,
                CURLOPT_FILE => $tFilePointer,
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_SSL_VERIFYPEER => false
            ]
        );

        $tLoop = 0;
        $tFailed = false;

        while (true) {
            curl_exec($tCurl);
            $tLoop++;

            $tError = curl_errno($tCurl);
            if ($tError !== 0) {
                $tHttpStatus = curl_getinfo($tCurl, CURLINFO_HTTP_CODE);

                // HTTP 5xx
                if ($tLoop < 3 && ($tHttpStatus >= 500 && $tHttpStatus < 600)) {
                    echo "HTTP {$tHttpStatus}, trying again...", PHP_EOL;
                    // try again after 1 second delay
                    usleep(1000000);
                    continue;
                }

                echo "CURL Error Message: ", curl_error($tCurl), PHP_EOL;
                $tFailed = true;
            }

            break;
        }

        curl_close($tCurl);

        fclose($tFilePointer);

        if ($tFailed) {
            unlink($uFile);
            return false;
        }

        return $uFile;
    }
}
