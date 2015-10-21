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



