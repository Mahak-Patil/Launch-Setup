<?php
// This script is the modified version of "submit.php" provided by Jeremy Hajek.

session_start();
var_dump($_POST);
if(!empty($_POST)){
echo $_POST['email'];
echo $_POST['phone'];
}
else
{
echo "post empty";
}
$uploaddir = '/tmp/';
$uploadfile = $uploaddir . basename($_FILES['userfile']['name']);
print '<pre>';
if (move_uploaded_file($_FILES['userfile']['tmp_name'], $uploadfile)) {
  echo "File is valid, and successfully uploaded.\n";
} else {
    echo "Possible file upload!\n";
}
echo 'Here is some more debugging info:';
print_r($_FILES);
print "</pre>";
require 'vendor/autoload.php';

#use Aws\S3\S3Client;
#$client = S3Client::factory();
$s3 = new Aws\S3\S3Client([
    'version' => 'latest',
    'region'  => 'us-east-1'
]);
#print_r($s3);
$bucket = uniqid("CharlieBucketsGallore",false);
#$result = $s3->createBucket(array(
#    'Bucket' => $bucket
#));
#
## AWS PHP SDK version 3 create bucket
$result = $s3->createBucket([
    'ACL' => 'public-read',
    'Bucket' => $bucket
]);
# PHP version 3
$result = $client->putObject([
    'ACL' => 'public-read',
    'Bucket' => $bucket,
   'Key' => $uploadfile
   'ContentType' => $_FILES['userfile']['type'],
   'Body' => fopen($uploadfile,'r+')
]);  
$url = $result['ObjectURL'];
echo $url;
$rds = new Aws\Rds\RdsClient([
    'version' => 'latest',
    'region'  => 'us-east-1'
]);
$result = $rds->describeDBInstances(array(
    'DBInstanceIdentifier' => 'ITMO-544-Database'
));	
$endpoint = $result['DBInstances']['Endpoint']['Address']
    echo "============\n". $endpoint . "================";^M
//echo "begin database";^M
$link = mysqli_connect($endpoint,"controller","ilovebunnies") or die("Error " . mysqli_error($link));
/* check connection */
if (mysqli_connect_errno()) {
    printf("Connect failed: %s\n", mysqli_connect_error());
    exit();
}
else {
echo "All is good";
}

if (!($stmt = $link->prepare("INSERT INTO ITMO-544-Table (uName, email,phone,rawS3Url,finishedS3rawurl,jpgFileName,state) VALUES (?,?,?,?,?,?,?)"))) {
    echo "Prepare failed: (" . $link->errno . ") " . $link->error;
}
$uname="Mahak Patil";
$email = $_POST['useremail'];
$phoneforsms = $_POST['phone'];
$raws3url = $url; 
$finisheds3url = "none";
$jpegfilename = basename($_FILES['userfile']['name']);
$state=0;
$stmt->bind_param("ssssssi",$uname,$email,$phoneforsms,$raws3url,$finisheds3url,$jpegfilename,$state);
if (!$stmt->execute()) {
    echo "Execute failed: (" . $stmt->errno . ") " . $stmt->error;
}
printf("%d Row inserted.\n", $stmt->affected_rows);
$stmt->close();
$link->real_query("SELECT * FROM ITMO-544-Table");
$res = $link->use_result();
echo "Result set order...\n";
while ($row = $res->fetch_assoc()) {
    echo $row['id'] . " " . $row['email']. " " . $row['phone'];
}
$link->close();
?> 