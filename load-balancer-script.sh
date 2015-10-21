#!/bin/bash
#this script creates a load load balancer, attaches the 3 already launched EC2 instances and finally, creates a health and cookie-stickiness policy for the load balancer

#creates a load balancer
aws elb create-load-balancer --load-balancer-name ITMO-544-mini-project-load-balancer --listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" --availability-zones us-west-2a us-west-2b

#assumes an array contains the instance IDs and the instances register with the load balancer
aws elb register-instances-with-load-balancer --load-balancer-name ITMO-544-mini-project-load-balancer --instances *insert instances here*

#configure a health check policy
aws elb configure-health-check --load-balancer-name ITMO-544-mini-project-load-balancer --health-check Target=HTTP:80/png,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3

#congiguring a cookie-stickiness policy for the lad balancer
aws elb create-lb-cookie-stickiness-policy --load-balancer-name ITMO-544-mini-project-load-balancer --policy-name ITMO-544-cookie-policy --cookie-expiration-period 60

#Create cloud watch metrics
aws cloudwatch put-metric-alarm --alarm-name cpugreaterthan30 --alarm-description "Alarm when CPU exceeds 30 percent" --metric-name CPUUtilization 
--namespace AWS/EC2 --statistic Average --period 300 --threshold 30 --comparison-operator GreaterThanThreshold  --dimensions 
 Name=InstanceId,Value=i-12345678 --evaluation-periods 2 --alarm-actions arn:aws:sns:us-east-1:111122223333:MyTopic --unit Percent


#Create Autoscaling group including items
aws autoscaling create-auto-scaling-group --auto-scaling-group-name itmo-544-extended-auto-scaling-group-2 --launch-configuration-name itmo544-launch-config --load-balancer-names ITMO-544-mini-project-load-balancer  --health-check-type ELB --min-size 3 --max-size 6 --desired-capacity 3 --default-cooldown 600 --health-check-grace-period 120 --vpc-zone-identifier subnet-cccce295 

#Create AWS RDS instances and set schema