<?php
# This script is based of the script provided by Jeremy Hajek.
# Create the RDS schema here when the install-webserver.sh application is first installed.
# This file will be run one time at launch of the web-application to initialize the DB schema
# Then in your shell script change this file to have permission 600 so no one can run it again afterwards.

//conection: 
$rds = new Aws\Rds\RdsClient([
 'version' => 'latest',
 'region'  => 'us-east-1'
]);
$result = $rds->describeDBInstances(array(
 'DBInstanceIdentifier' => 'ITMO-544-Database'
));
$endpoint = $result['DBInstances'][0]['Endpoint']['Address'];
$link = mysqli_connect($endpoint,"controller","ilovebunnies") or die("Error " . mysqli_error($link)); 

echo "Here is the result: " . $link;


$link->query("CREATE TABLE ITMO-544-Table 
(
ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
uName VARCHAR(20),
email VARCHAR(20),
phone VARCHAR(20),
rawS3Url VARCHAR(256),
finishedS3Url VARCHAR(256),
jpgFileName VARCHAR(256),
state tinyint(3),
CHECK(state IN(0,1,2)),
datetime timestamp,
)");

shell_exec("chmod 600 setup.php"); //NEED TO VERIFY THIS!!
?>
