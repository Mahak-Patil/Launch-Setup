<?php

# Create the RDS schema here when the install-webserver.sh application is first installed.
# This file will be run one time at launch of the web-application to initialize the DB schema
# Then in your shell script change this file to have permission 600 so no one can run it again afterwards.

//conection: 
echo "Hello world"; 
$link = mysqli_connect("localhost","ITMO-544-Fall-2015","ilovebunnies","3306") or die("Error " . mysqli_error($link)); 

echo "Here is the result: " . $link;


$sql = "CREATE TABLE comments 
(
ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
uName VARCHAR(20),
email VARCHAR(20),
phone VARCHAR(20),
rawS3Url VARCHAR(256),
finishedS3Url VARCHAR(256),
jpgFileName VARCHAR(256),
state TINYINT(3),
Timestamp (DateTime),
)";

$con->query($sql);
?>
