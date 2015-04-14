<?php return [
    "database" => [
       "host"     => "localhost",
       "username" => "root",
       "password" => ""
    ],
    "adapters" => [
        [
            "class"  => "Vendor\\XmlAdapters\\Sample",
            "config" => [
                "url" => "http://www.domain.com/path/filename.xml"
            ]
        ]
    ]
];
