#!/bin/bash

# This script launches: database subnet, AWS RDS instances, EC2 instances,read replica of created database, load balancer, cloud metrics and autoscaling group.
# This script need 4 arguments: security group id, subnet id, key name and IAM profile.
# launch database here:

# creates a database subnet
aws rds create-db-subnet-group --db-subnet-group-name ITMO544-Database-Subnet --subnet-ids subnet-0fdfdd78 subnet-f7a25eca  --db-subnet-group-description "Database Subnet"

# create AWS RDS instances
rds-create-db-instance ITMO-544-db --engine MySQL 

# launch instances here:
aws ec2 run-instances --image-id ami-d05e75b8 --count 3 --instance-type t2.micro --user-data install-webserver.sh --security-group-ids $1 --subnet-id $2 --key-name $3 --iam-profile $4  --associate-public-ip-address

#Create read replica
aws rds-create-db-instance-read-replica ITM0-544-db-replica --source-db-instance-identifier-value ITMO-544-Database

# launch load balancer
aws elb configure-health-check --load-balancer-name ITMO-544-lb --health-check Target=HTTP:80/index.html,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3

#Create Autoscaling group including items
aws autoscaling create-auto-scaling-group --auto-scaling-group-name ITMO-544-extended-auto-scaling-group-1 --launch-configuration-name ITMO-544-launch-config --load-balancer-names ITMO-544-lb --health-check-type ELB --min-size 3 --max-size 6 --desired-capacity 3 --default-cooldown 600 --health-check-grace-period 120 --vpc-zone-identifier subnet-cccce295 