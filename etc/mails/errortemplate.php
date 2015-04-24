<html>
<head>
	<title>XmlImport Error</title>
    <style type="text/css">
        body {
            font-family: 'Open Sans', 'Helvetica Neue', Helvetica, Arial, sans-serif;
        }

        pre {
            font-family: Consolas, 'Lucida Console', 'Courier New', monospace;
        }
    </style>
</head>
<body>
	<h1>XmlImport Error</h1>

    <h2><?php echo get_class($exception); ?></h2>

	<strong><?php echo $exception->getMessage(); ?></strong>
	<pre><?php echo $exception; ?></pre>
</body>
</html>