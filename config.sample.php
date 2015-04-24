<?php return array(
    "database" => array(
        "conn"     => "mysql:host=localhost;dbname=xmlimport",
        "username" => "root",
        "password" => ""
    ),
    "mail" => array(
        "from"          => "xmlimport@github.com",
        "to"            => "eser@sent.com",
        "headers" => array(
            "X-Mailer" => "PHP/" . phpversion()
        )
    ),
    "adapters" => array(
        array(
            "class"  => "Vendor\\XmlAdapters\\Sample",
            "config" => array(
                "id"        => 1,
                "name"      => "Sample",
                "url"       => "http://www.domain.com/path/filename.xml",
                "sql.sync"  => "etc/sql/sync.sample.sql",
                "downloads" => "downloaded/"
            )
        )
    )
);
