# Endava Challenge Soliton

## Description

This bash script will be solution for https://github.com/Endava-Sofia/endava-devops-challenge
Also can be used for creating AWS Key Pair, VPC, Secirity Groups, RDS, EC2 instance, Load Balancer for Web Application and CloudWatch Alerts.
Script assume that user already install AWC CLI and configurate his/her account and Amazon SNS.

## Script Info

1) Create a Key Pair.
2) Create VPC, two public(for Load Balancer and EC2 instance) subnets, two private subnets(for EC2 instance and RDS service), Internet Gateway and routing table.
3) Create VPC Security Group for SSH and HTTP, and access to RDS from EC2 instances.
4) Create RDS Subnet group.
5) Create RDS with mysql engine.
6) Create two EC2 instances.
7) Create Load Balancer Web Application with needed target group and listener.
8) Create CloudWatch for EC2, DB RDS and Load Balancer with few alerms.

## To Do

1) Make the code more readable.
2) Make the code more identical.
3) Add Automate service-fail-over part in the script.

## Used Materials

1) https://github.com/kovarus/aws-cli-create-vpcs/blob/master/aws-cli-create-vpc.sh
2) https://github.com/swoodford/aws/blob/master/cloudwatch-create-alarms.sh
3) https://cloudaffaire.com/how-to-create-an-application-load-balancer-using-aws-cli/
4) https://docs.aws.amazon.com/cli/latest/userguide/cli-services-ec2-instances.html
5) https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/TUT_WebAppWithRDS.html
6) https://docs.aws.amazon.com/elasticloadbalancing/latest/application/tutorial-application-load-balancer-cli.html
7) https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html
