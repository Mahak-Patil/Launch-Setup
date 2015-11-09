#!/bin/bash

# This script launches: database subnet, AWS RDS instances, EC2 instances,read replica of created database, load balancer, cloud metrics and autoscaling group.
# This script needs 7 arguments: ami image-id, number of EC2 instances, instance type, security group ids, subnet id, key name and iam profile


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

#aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $SCALENAME

#aws autoscaling delete-launch-configuration --launch-configuration-name $LAUNCHCONF

#aws autoscaling update-auto-scaling-group --auto-scaling-group-name $SCALENAME --min-size 0 --max-size 0

#aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $SCALENAME
#aws autoscaling delete-launch-configuration --launch-configuration-name $LAUNCHCONF
fi

echo "All done"



echo "Enter arguments in the following order: ami image id (e.g ami-d05e75b8), number of EC2 instances needed (e.g 3), instance type (e.g.t2.micro), security group ID (e.g. sg- ), subnet ID(e.g. subnet- ), key pair name (make sure the path is correct) and IAM Profile: "


# launch database here:

# creates a database subnet
aws rds create-db-subnet-group --db-subnet-group-name ITMO544-Database-Subnet --subnet-ids subnet-0fdfdd78 subnet-f7a25eca  --db-subnet-group-description "Database Subnet"

# create AWS RDS instances
mapfile -t dbInstanceARR < <(aws rds describe-db-instances --output json | grep "\"DBInstanceIdentifier" | sed "s/[\"\:\, ]//g" | sed "s/DBInstanceIdentifier//g" )

if [ ${#dbInstanceARR[@]} -gt 0 ]
   then
   echo "Deleting existing RDS database-instances"
   LENGTH=${#dbInstanceARR[@]}

      for (( i=0; i<${LENGTH}; i++));
      do
      if [ ${dbInstanceARR[i]} == "ITMO-544-db" ] 
     then 
      echo "db exists"
     else
     aws rds create-db-instance --db-instance-identifier ITMO-544-db --db-instance-class db.t1.micro --engine MySQL --master-username controller --master-user-password ilovebunnies --allocated-storage 5
      fi  
     done
fi

# launch instances here:
aws ec2 run-instances --image-id ami-d05e75b8 --count 3 --instance-type t2.micro --user-data install-webserver.sh --security-group-ids $1 --subnet-id $2 --key-name $3 --iam-profile $4  --associate-public-ip-address

#Create read replica
aws rds-create-db-instance-read-replica ITM0-544-db-replica --source-db-instance-identifier-value ITMO-544-Database

# launch load balancer
aws elb configure-health-check --load-balancer-name ITMO-544-lb --health-check Target=HTTP:80/index.html,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3

#Create cloud watch metrics
aws cloudwatch put-metric-alarm --alarm-name cpugreaterthan30 --alarm-description "Alarm when CPU exceeds 30 percent" --metric-name CPUUtilization 
--namespace AWS/EC2 --statistic Average --period 300 --threshold 30 --comparison-operator GreaterThanThreshold  --dimensions 
 Name=InstanceId,Value=i-12345678 --evaluation-periods 2 --alarm-actions arn:aws:sns:us-east-1:111122223333:MyTopic --unit Percent

#Create Autoscaling group including items
aws autoscaling create-auto-scaling-group --auto-scaling-group-name ITMO-544-extended-auto-scaling-group-1 --launch-configuration-name ITMO-544-launch-config --load-balancer-names ITMO-544-lb --health-check-type ELB --min-size 3 --max-size 6 --desired-capacity 3 --default-cooldown 600 --health-check-grace-period 120 --vpc-zone-identifier subnet-cccce295 