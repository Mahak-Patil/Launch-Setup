<html>
<head><title>Gallery</title>
 <!--jQuery-->
  <script src="http://code.jquery.com/jquery-1.10.2.min.js"></script>
  <!--Fotorama-->
  <link href="fotorama.css" rel="stylesheet">
  <script src="fotorama.js"></script>
</head>
<body>

<?php
// NOTE: code provided by Jeremy Hajek is modified.
session_start();
require 'vendor/autoload.php';

//create client for s3 bucket
use Aws\Rds\RdsClient;
$client = RdsClient::factory(array(
'region'  => 'us-east-1'
));

$result = $client->describeDBInstances(['DBInstanceIdentifier' => 'ITMO-544-Database',
]);

$endpoint = "";
$endpoint = $result['DBInstances'][0]['Endpoint']['Address'];

//echo "begin database";
$link = mysqli_connect($endpoint,"controller","ilovebunnies","ITMO-544-Database") or die("Error " . mysqli_error($link));

/* check connection */
if (mysqli_connect_errno()) {
    printf("Connect failed: %s\n", mysqli_connect_error());
    exit();
}

//below line is unsafe - $email is not checked for SQL injection -- don't do this in real life or use an ORM instead
$link->real_query("SELECT * FROM ITM)-544-Database");
//$link->real_query("SELECT * FROM items");
$res = $link->use_result();
$link->close();
?>

</body>
</html>
