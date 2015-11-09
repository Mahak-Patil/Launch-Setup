# Launch-Setup
# Notes for launch.sh

This script first performs a cleanup: terminates ec2 instances, rds etc so that it gets a clean, freash start.

The launch setup will begin after cleanup.
 Script will ask for 7 commandline arguments in this order:

1) ami image-id
2) count
3) instance-type
4) security-group-ids
5) subnet id
6) Key name
7) iam profile

A database subnet (ITMO-544-Database-Subnet) and a database instance (ITMO-544-Database) will be created.
username is controller and password is ilovebunnies.

An elastic load balancer (ITMO-544-Load-Balancer) will be launched. A health policy will be attached.

Based on the received command line inputs, ec2 instances will be launched now and "install-webserver.sh" will be loaded on all.
These ec2 instances will then be registered to the load balancer.