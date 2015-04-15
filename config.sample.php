<?php return [
    "database" => [
       "conn"     => "mysql:host=localhost;dbname=xmlimport",
       "username" => "root",
       "password" => ""
    ],
    "adapters" => [
        [
            "class"  => "Vendor\\XmlAdapters\\Sample",
            "config" => [
                "id" => 1,
                "url" => "http://www.domain.com/path/filename.xml"
            ]
        ]
    ]
];
