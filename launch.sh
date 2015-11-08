#!/bin/bash

# This script launches: database subnet, AWS RDS instances, EC2 instances,read replica of created database, load balancer, cloud metrics and autoscaling group.
# This script needs 7 arguments: ami image-id, number of EC2 instances, instance type, security group ids, subnet id, key name and iam profile

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