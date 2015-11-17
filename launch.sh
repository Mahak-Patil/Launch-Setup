#!/bin/bash

# This script launches: database subnet, AWS RDS instances, EC2 instances,read replica of created database, load balancer, cloud metrics and autoscaling group.
# This script needs 7 arguments: ami image-id, number of EC2 instances, instance type, security group ids, subnet id, key name and iam profile

echo "Initiating cleaup... Please be patient and wait for the next prompt"


#cleanup script provided by Jeremy Hajek starts here:

declare -a cleanupARR 
declare -a cleanupLBARR
declare -a dbInstanceARR

aws ec2 describe-instances --filter Name=instance-state-code,Values=16 --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g"

mapfile -t cleanupARR < <(aws ec2 describe-instances --filter Name=instance-state-code,Values=16 --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g")

echo "the output is ${cleanupARR[@]}"

aws ec2 terminate-instances --instance-ids ${cleanupARR[@]} 

echo "Cleaning up existing Load Balancers"
mapfile -t cleanupLBARR < <(aws elb describe-load-balancers --output json | grep LoadBalancerName | sed "s/[\"\:\, ]//g" | sed "s/LoadBalancerName//g")

echo "The LBs are ${cleanupLBARR[@]}"

LENGTH=${#cleanupLBARR[@]}
echo "ARRAY LENGTH IS $LENGTH"
for (( i=0; i<${LENGTH}; i++)); 
  do
  aws elb delete-load-balancer --load-balancer-name ${cleanupLBARR[i]} --output text
  sleep 1
done

# Delete existing RDS  Databases
# Note if deleting a read replica this is not your command 
mapfile -t dbInstanceARR < <(aws rds describe-db-instances --output json | grep "\"DBInstanceIdentifier" | sed "s/[\"\:\, ]//g" | sed "s/DBInstanceIdentifier//g" )

if [ ${#dbInstanceARR[@]} -gt 0 ]
   then
   echo "Deleting existing RDS database-instances"
   LENGTH=${#dbInstanceARR[@]}  

   # http://docs.aws.amazon.com/cli/latest/reference/rds/wait/db-instance-deleted.html
      for (( i=0; i<${LENGTH}; i++));
      do 
      aws rds delete-db-instance --db-instance-identifier ${dbInstanceARR[i]} --skip-final-snapshot --output text
      aws rds wait db-instance-deleted --db-instance-identifier ${dbInstanceARR[i]} --output text
      sleep 1
   done
fi

# Create Launchconf and Autoscaling groups

LAUNCHCONF=(`aws autoscaling describe-launch-configurations --output json | grep LaunchConfigurationName | sed "s/[\"\:\, ]//g" | sed "s/LaunchConfigurationName//g"`)

SCALENAME=(`aws autoscaling describe-auto-scaling-groups --output json | grep AutoScalingGroupName | sed "s/[\"\:\, ]//g" | sed "s/AutoScalingGroupName//g"`)

echo "The asgs are: " ${SCALENAME[@]}
echo "the number is: " ${#SCALENAME[@]}

if [ ${#SCALENAME[@]} -gt 0 ]
  then
echo "SCALING GROUPS to delete..."
#aws autoscaling detach-launch-

aws autoscaling delete-auto-scaling-group --auto-scaling-group-name ITMO-544-Auto-Scaling-Group

aws autoscaling delete-launch-configuration --launch-configuration-name ITMO-544-Launch-Configuration

#aws autoscaling update-auto-scaling-group --auto-scaling-group-name $SCALENAME --min-size 0 --max-size 0

#aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $SCALENAME
#aws autoscaling delete-launch-configuration --launch-configuration-name $LAUNCHCONF
fi
echo "All done! Thank you for your patience"

echo "\nEnter arguments in the following order: ami image id (e.g ami-d05e75b8), number of EC2 instances needed (e.g 3), instance type (e.g.t2.micro), security group ID (e.g. sg- ), subnet ID(e.g. subnet- ), key pair name (make sure the path is correct) and IAM Profile: "

# creating database subnet
DbSubnetID=$(aws rds create-db-subnet-group --db-subnet-group-name ITMO-544-Database-Subnet --subnet-ids $SubnetID1 $SubnetID2 --db-subnet-group-description "Database subnet" --output=text)
echo "\nDatabase subnet created: "$DbSubnetID
# creating the database. Initial check done in previous, cleanup section.
aws rds create-db-instance --db-instance-identifier ITMO-544-Database --allocated-storage 5 --db-instance-class db.t1.micro --engine MySQL --master-username controller --master-user-password ilovebunnies --db-subnet-group-name ITMO-544-Database-Subnet --db-name ITMO-544-Database 
echo "Sleeping for one minute"
for i in {0..60}
do
echo -ne '.'
sleep 1
done

# creating elb 
ElbUrl=$(aws elb create-load-balancer --load-balancer-name ITMO-544-Load-Balancer --security-groups $4 --subnets $5 --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --output=text)
echo "\nLaunched ELB and sleeping for one minute"
for i in {0..60}
 do
  echo -ne '.'
  sleep 1;
  done

# configuring health check
aws elb configure-health-check --load-balancer-name ITMO-544-Load-Balancer --health-check Target=HTTP:80/index.php,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3
echo -e "\nConfigured ELB health check. Proceeding to launch EC2 instances"
  
# launching ec2 instances
aws ec2 run-instances --image-id $1 --count $2 --instance-type $3 --key-name $4 --user-data install-webserver.sh --subnet-id $5 --output text --security-group-ids $4 --iam-instance-profile Name=$7
echo -e "\nLaunched 3 EC2 Instances and sleeping for one minute"
for i in {0..60}
 do
  echo -ne '.'
  sleep 1;
  done
  
 
# registering instances with crested elb
declare -a instance_list
mapfile -t instance_list < <(aws ec2 run-instances --image-id $1 --count $2 --instance-type $3 --key-name $4 --security-group-ids $5 --subnet-id $6 --associate-public-ip-address --iam-instance-profile Name=$7 --user-data install-webserver.sh --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g")
aws ec2 wait instance-running --instance-ids ${instance_list[@]} 
aws ec2 wait instance-running --instance-ids ${instance_list[@]} 
echo "Following instances running: ${instance_list[@]}" 
echo "\nAdding above to an array and registering with the load balancer." 
len=${#instance_list[@]}
for (( i=0; i<${#instance_list[@]}; i++)); 
  do
  echo "Registering ${instance_list[$i]} with load-balancer ITMO-544-Load-Balancer" 
  aws elb register-instances-with-load-balancer --load-balancer-name ITMO-544-Load-Balancer --instances ${instance_list[$i]} --output=table 
echo -e "\n Sleeping for one minute to complete the process."
    for y in {0..60} 
    do
      echo -ne '.'
      sleep 1
    done
 echo "\n"
done

# creating launch configuration
aws autoscaling create-launch-configuration --launch-configuration-name ITMO-544-Launch-Configuration --image-id $1 --key-name $6 --security-groups $4 --instance-type $3 --user-data install-webserver.sh --iam-instance-profile $7

# creating autoscaling group and autoscaling policy
aws autoscaling create-auto-scaling-group --auto-scaling-group-name ITMO-544-Auto-Scaling-Group --launch-configuration-name ITMO-544-Launch-Configuration --load-balancer-names ITMO-544-Load-Balancer --health-check-type ELB --min-size 3 --max-size 6 --desired-capacity 3 --default-cooldown 600 --health-check-grace-period 120 --vpc-zone-identifier $5
aws autoscaling put-scaling-policy --auto-scaling-group-name ITMO-544-Auto-Scaling-Group --policy-name ITMO-544-Scaling-Policy --scaling-adjustment 1 --adjustment-type ExactCapacity

# creating cloudwatch metric. got most of these directly from the documentation!
aws cloudwatch put-metric-alarm --alarm-name ITMO-544-Alarm --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 60 --threshold 30 --comparison-operator GreaterThanOrEqualToThreshold --dimensions "Name=AutoScalingGroup,Value=ITMO-544-Auto-Scaling-Group" --evaluation-periods 1 --alarm-actions arn:aws:sns:us-east-1:111122223333:MyTopic --unit Percent

# Create read replica
aws rds-create-db-instance-read-replica ITM0-544-Database-Replica --source-db-instance-identifier-value ITMO-544-Database --output=text 

# Creating sns topic
TopicARN = $(aws sns create-topic --name ITMO-544-Notification)

# Setting an attribute of the above topic to a new value
aws sns set-topic-attributes --topic-arn $TopicARN --attribute-name DisplayName --attribute-value ITMO-544

# subscribing an endpoint to a topic
aws sns subscribe --topic-arn $TopicARN --protocol sms --notification-endpoint 13123949795
