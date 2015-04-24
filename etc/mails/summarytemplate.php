<html>
<head>
	<title>XmlImport Summary</title>
    <style type="text/css">
        body {
            font-family: 'Open Sans', 'Helvetica Neue', Helvetica, Arial, sans-serif;
        }

        pre {
            font-family: Consolas, 'Lucida Console', 'Courier New', monospace;
        }

        table {
            border-collapse: collapse;
        }

        td {
            padding: 5px;
            vertical-align: top;
        }
    </style>
</head>
<body>
	<h1>XmlImport Summary</h1>

    <h2>Jobs</h2>

    <table border="1">
        <tr>
            <th>Job</th>
            <th>Status</th>
            <th>Time</th>
            <th>Output</th>
        </tr>
	<?php foreach ($jobs as $job) { ?>
        <tr>
            <td><strong><?php echo $job[0]; ?></strong></td>
            <td><?php echo $job[1]; ?></td>
            <td><?php echo number_format($job[2], 4); ?>s</td>
            <td><?php echo nl2br($job[3]); ?></td>
        </tr>
    <?php } ?>
    </table>

    <br />
    <br />

    <em>Completed in <?php echo number_format($timespan, 4); ?> seconds.</em>
</body>
</html>