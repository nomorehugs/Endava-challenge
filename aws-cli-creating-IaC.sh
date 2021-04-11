#!/bin/bash

# Script will be for solution for https://github.com/Endava-Sofia/endava-devops-challenge
# Also can be used for creating AWS Key Pair, VPC, Secirity Groups, RDS database, EC2 instance, Load Balancer for Web Application and CloudWatch Alerts
# Script assume that user already install AWC CLI and configurate his/her account

### Variables
# For Step 01.
ENDAVA_KEY_PAIR=EndavaKeyPair
# For Step 02.
AWS_REGION="eu-west-2"
VPC_NAME="Endava VPC"
VPC_CIDR="10.0.0.0/16"
SUBNET_PUBLIC_CIDR="10.0.1.0/24"
SUBNET_PUBLIC_AZ="eu-west-2a"
SUBNET_PUBLIC_NAME="PUBLIC 1 - 10.0.1.0 - eu-west-2a"
SUBNET_PUBLIC_LB_CIDR="10.0.4.0/24"
SUBNET_PUBLIC_LB_AZ="eu-west-2b"
SUBNET_PUBLIC_LB_NAME="PUBLIC 2 - 10.0.4.0 - eu-west-2b"
SUBNET_PRIVATE_CIDR="10.0.2.0/24"
SUBNET_PRIVATE_AZ="eu-west-2a"
SUBNET_PRIVATE_NAME="PRIVATE 1 - 10.0.2.0 - eu-west-2a"
SUBNET_PRIVATE_DB_CIDR="10.0.3.0/24"
SUBNET_PRIVATE_DB_AZ="eu-west-2b"
SUBNET_PRIVATE_DB_NAME="PRIVATE 2 - 10.0.3.0 - eu-west-2b"
CHECK_FREQUENCY=5
# For Step 03.
MY_IP=`curl https://checkip.amazonaws.com`
# For Step 04.
DB_SUBNET_GROUP_TEMPLATE_URL=https://raw.githubusercontent.com/nomorehugs/Endava-challenge/main/files/db_subnet_group.json
DB_SUBNET_GROUP_FILE=db_subnet_group.json
# For Step 05.
DB_SUBNET_GROUP=endava_db_subnet_group
DB_MASTER_USER=admin
DB_MASTER_PASSWORD=secret99
DB_ID=EndavaDB
# For Step 06. 
EC2_USERDATA_TEMPLETE_URL=https://raw.githubusercontent.com/nomorehugs/Endava-challenge/main/files/user_data_template.txt
EC2_USERDATA_FILE_1=user_data_one.txt
EC2_USERDATA_FILE_2=user_data_two.txt
# For Step 08.
ALARMACTION="arn:aws:sns:eu-west-2:542331399637:ENDAVA-ALERTS"

### 01. Creating Key Pair
echo "01. Creating Key Pair"
echo "---------------------"
aws ec2 create-key-pair --key-name $ENDAVA_KEY_PAIR --query 'KeyMaterial' --output text > $ENDAVA_KEY_PAIR.pem
aws ec2 describe-key-pairs --key-name $ENDAVA_KEY_PAIR
chmod 400 $ENDAVA_KEY_PAIR.pem
echo "Key Pair $ENDAVA_KEY_PAIR is created!"

### 02. Creating everything into the VPC
# Used script from here - https://github.com/kovarus/aws-cli-create-vpcs/blob/master/aws-cli-create-vpc.sh
echo "02. Creating VPC"
echo "---------------------"

# Create VPC
echo "Creating VPC in preferred region..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --query 'Vpc.{VpcId:VpcId}' \
  --output text \
  --region $AWS_REGION)
echo "  VPC ID '$VPC_ID' CREATED in '$AWS_REGION' region."

# Add Name tag to VPC
aws ec2 create-tags \
  --resources $VPC_ID \
  --tags "Key=Name,Value=$VPC_NAME" \
  --region $AWS_REGION
echo "  VPC ID '$VPC_ID' NAMED as '$VPC_NAME'."

# Create Public Subnet
echo "Creating Public Subnet..."
SUBNET_PUBLIC_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $SUBNET_PUBLIC_CIDR \
  --availability-zone $SUBNET_PUBLIC_AZ \
  --query 'Subnet.{SubnetId:SubnetId}' \
  --output text \
  --region $AWS_REGION)
echo "  Subnet ID '$SUBNET_PUBLIC_ID' CREATED in '$SUBNET_PUBLIC_AZ'" \
  "Availability Zone."

# Add Name tag to Public Subnet
aws ec2 create-tags \
  --resources $SUBNET_PUBLIC_ID \
  --tags "Key=Name,Value=$SUBNET_PUBLIC_NAME" \
  --region $AWS_REGION
echo "  Subnet ID '$SUBNET_PUBLIC_ID' NAMED as" \
  "'$SUBNET_PUBLIC_NAME'."

# Create Public LB Subnet
echo "Creating Public LB Subnet..."
SUBNET_PUBLIC_LB_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $SUBNET_PUBLIC_LB_CIDR \
  --availability-zone $SUBNET_PUBLIC_LB_AZ \
  --query 'Subnet.{SubnetId:SubnetId}' \
  --output text \
  --region $AWS_REGION)
echo "  Subnet ID '$SUBNET_PUBLIC_LB_ID' CREATED in '$SUBNET_PUBLIC_LB_AZ'" \
  "Availability Zone."

# Add Name tag to Public LB Subnet
aws ec2 create-tags \
  --resources $SUBNET_PUBLIC_LB_ID \
  --tags "Key=Name,Value=$SUBNET_PUBLIC_LB_NAME" \
  --region $AWS_REGION
echo "  Subnet ID '$SUBNET_PUBLIC_LB_ID' NAMED as" \
  "'$SUBNET_PUBLIC_LB_NAME'."

# Create Private Subnet
echo "Creating Private Subnet..."
SUBNET_PRIVATE_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $SUBNET_PRIVATE_CIDR \
  --availability-zone $SUBNET_PRIVATE_AZ \
  --query 'Subnet.{SubnetId:SubnetId}' \
  --output text \
  --region $AWS_REGION)
echo "  Subnet ID '$SUBNET_PRIVATE_ID' CREATED in '$SUBNET_PRIVATE_AZ'" \
  "Availability Zone."

# Add Name tag to Private Subnet
aws ec2 create-tags \
  --resources $SUBNET_PRIVATE_ID \
  --tags "Key=Name,Value=$SUBNET_PRIVATE_NAME" \
  --region $AWS_REGION
echo "  Subnet ID '$SUBNET_PRIVATE_ID' NAMED as '$SUBNET_PRIVATE_NAME'."

# Create Private Subnet DB
echo "Creating DB Private Subnet..."
SUBNET_PRIVATE_DB_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $SUBNET_PRIVATE_DB_CIDR \
  --availability-zone $SUBNET_PRIVATE_DB_AZ \
  --query 'Subnet.{SubnetId:SubnetId}' \
  --output text \
  --region $AWS_REGION)
echo "  Subnet ID '$SUBNET_PRIVATE_DB_ID' CREATED in '$SUBNET_PRIVATE_DB_AZ'" \
  "Availability Zone."

# Add Name tag to Private Subnet DB
aws ec2 create-tags \
  --resources $SUBNET_PRIVATE_DB_ID \
  --tags "Key=Name,Value=$SUBNET_PRIVATE_DB_NAME" \
  --region $AWS_REGION
echo "  Subnet ID '$SUBNET_PRIVATE_DB_ID' NAMED as '$SUBNET_PRIVATE_DB_NAME'."

# Create Internet gateway
echo "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
  --output text \
  --region $AWS_REGION)
echo "  Internet Gateway ID '$IGW_ID' CREATED."

# Attach Internet gateway to your VPC
aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID \
  --region $AWS_REGION
echo "  Internet Gateway ID '$IGW_ID' ATTACHED to VPC ID '$VPC_ID'."

# Create Route Table
echo "Creating Route Table..."
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --query 'RouteTable.{RouteTableId:RouteTableId}' \
  --output text \
  --region $AWS_REGION)
echo "  Route Table ID '$ROUTE_TABLE_ID' CREATED."

# Create route to Internet Gateway
RESULT=$(aws ec2 create-route \
  --route-table-id $ROUTE_TABLE_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID \
  --region $AWS_REGION)
echo "  Route to '0.0.0.0/0' via Internet Gateway ID '$IGW_ID' ADDED to" \
  "Route Table ID '$ROUTE_TABLE_ID'."

# Associate Public Subnet with Route Table
RESULT=$(aws ec2 associate-route-table  \
  --subnet-id $SUBNET_PUBLIC_ID \
  --route-table-id $ROUTE_TABLE_ID \
  --region $AWS_REGION)
echo "  Public Subnet ID '$SUBNET_PUBLIC_ID' ASSOCIATED with Route Table ID" \
  "'$ROUTE_TABLE_ID'."

# Enable Auto-assign Public IP on Public Subnet
aws ec2 modify-subnet-attribute \
  --subnet-id $SUBNET_PUBLIC_ID \
  --map-public-ip-on-launch \
  --region $AWS_REGION
echo "  'Auto-assign Public IP' ENABLED on Public Subnet ID" \
  "'$SUBNET_PUBLIC_ID'."

# Associate Public LB Subnet with Route Table
RESULT=$(aws ec2 associate-route-table  \
  --subnet-id $SUBNET_PUBLIC_LB_ID \
  --route-table-id $ROUTE_TABLE_ID \
  --region $AWS_REGION)
echo "  Public Subnet ID '$SUBNET_PUBLIC_LB_ID' ASSOCIATED with Route Table ID" \
  "'$ROUTE_TABLE_ID'."

# Enable Auto-assign Public IP on Public LB Subnet
aws ec2 modify-subnet-attribute \
  --subnet-id $SUBNET_PUBLIC_LB_ID \
  --map-public-ip-on-launch \
  --region $AWS_REGION
echo "  'Auto-assign Public IP' ENABLED on Public Subnet ID" \
  "'$SUBNET_PUBLIC_LB_ID'."

# Allocate Elastic IP Address for NAT Gateway
echo "Creating NAT Gateway..."
EIP_ALLOC_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --query '{AllocationId:AllocationId}' \
  --output text \
  --region $AWS_REGION)
echo "  Elastic IP address ID '$EIP_ALLOC_ID' ALLOCATED."

# Create NAT Gateway
NAT_GW_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $SUBNET_PUBLIC_ID \
  --allocation-id $EIP_ALLOC_ID \
  --query 'NatGateway.{NatGatewayId:NatGatewayId}' \
  --output text \
  --region $AWS_REGION)
FORMATTED_MSG="Creating NAT Gateway ID '$NAT_GW_ID' and waiting for it to "
FORMATTED_MSG+="become available.\n    Please BE PATIENT as this can take some "
FORMATTED_MSG+="time to complete.\n    ......\n"
printf "  $FORMATTED_MSG"
FORMATTED_MSG="STATUS: %s  -  %02dh:%02dm:%02ds elapsed while waiting for NAT "
FORMATTED_MSG+="Gateway to become available..."
SECONDS=0
LAST_CHECK=0
STATE='PENDING'
until [[ $STATE == 'AVAILABLE' ]]; do
  INTERVAL=$SECONDS-$LAST_CHECK
  if [[ $INTERVAL -ge $CHECK_FREQUENCY ]]; then
    STATE=$(aws ec2 describe-nat-gateways \
      --nat-gateway-ids $NAT_GW_ID \
      --query 'NatGateways[*].{State:State}' \
      --output text \
      --region $AWS_REGION)
    STATE=$(echo $STATE | tr '[:lower:]' '[:upper:]')
    LAST_CHECK=$SECONDS
  fi
  SECS=$SECONDS
  STATUS_MSG=$(printf "$FORMATTED_MSG" \
    $STATE $(($SECS/3600)) $(($SECS%3600/60)) $(($SECS%60)))
  printf "    $STATUS_MSG\033[0K\r"
  sleep 1
done
printf "\n    ......\n  NAT Gateway ID '$NAT_GW_ID' is now AVAILABLE.\n"

# Create route to NAT Gateway
MAIN_ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
  --filters Name=vpc-id,Values=$VPC_ID Name=association.main,Values=true \
  --query 'RouteTables[*].{RouteTableId:RouteTableId}' \
  --output text \
  --region $AWS_REGION)
echo "  Main Route Table ID is '$MAIN_ROUTE_TABLE_ID'."
RESULT=$(aws ec2 create-route \
  --route-table-id $MAIN_ROUTE_TABLE_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $NAT_GW_ID \
  --region $AWS_REGION)
echo "  Route to '0.0.0.0/0' via NAT Gateway with ID '$NAT_GW_ID' ADDED to" \
  "Route Table ID '$MAIN_ROUTE_TABLE_ID'."
echo "COMPLETED"


### 03. Creating VPC Security Groups
echo "03. Creating VPC Security Groups"
echo "---------------------"

# Debug
echo "My IP is $MY_IP"
# Debug End

VPC_SG_SSH_HTTP=$(aws ec2 create-security-group --group-name sg_SSH_HTTP_$VPC_ID --description "SSH and HTTP" --vpc-id $VPC_ID --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $VPC_SG_SSH_HTTP --protocol tcp --port 22 --cidr $MY_IP/32
aws ec2 authorize-security-group-ingress --group-id $VPC_SG_SSH_HTTP --protocol tcp --port 80 --cidr 0.0.0.0/0
echo "Security Group for SSH and HTTP $VPC_SG_SSH_HTTP is created!"

VPC_SG_DB=$(aws ec2 create-security-group --group-name sg_DB_$VPC_ID --description "DB" --vpc-id $VPC_ID --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $VPC_SG_DB --protocol tcp --port 3306 --source-group $VPC_SG_SSH_HTTP
echo "Security Group for DB $VPC_SG_DB is created!"

### 04. Creating DB Subnet Group
echo "04. Creating DB Subnet Group"
echo "---------------------"

wget $DB_SUBNET_GROUP_TEMPLATE_URL -O $DB_SUBNET_GROUP_FILE
sed -i "s/SUBNET1/$SUBNET_PRIVATE_ID/g" $DB_SUBNET_GROUP_FILE
sed -i "s/SUBNET2/$SUBNET_PRIVATE_DB_ID/g" $DB_SUBNET_GROUP_FILE

# Debug
cat $DB_SUBNET_GROUP_FILE
# Debug END

aws rds create-db-subnet-group --cli-input-json file://$DB_SUBNET_GROUP_FILE

### 05. Creating DB RDS
echo "05. Creating DB RDS"
echo "---------------------"

aws rds create-db-instance --db-instance-identifier $DB_ID --db-instance-class db.t2.small --engine mysql \
	--master-username $DB_MASTER_USER --master-user-password $DB_MASTER_PASSWORD \
	--allocated-storage 20 --vpc-security-group-ids $VPC_SG_DB --db-subnet-group-name $DB_SUBNET_GROUP

echo "Waiting 1 minute... instance to be ready."
sleep 60
echo "Waiting 1 minute... instance to be ready."
sleep 60
echo "Waiting 1 minute... instance to be ready."
sleep 60
echo "Waiting 1 minute... instance to be ready."
sleep 60
echo "Waiting 1 minute... instance to be ready."
sleep 60

RDS_DB_ENDPOINT=$(aws rds describe-db-instances --query "DBInstances[*].Endpoint.Address" --output text)
echo "Database RDS $RDS_DB_ENDPOINT is created!"

### 06. Creating EC2 Instances
echo "06. Creating EC2 Instances"
echo "---------------------"

# Creating first EC2
wget $EC2_USERDATA_TEMPLETE_URL -O $EC2_USERDATA_FILE_1
sed -i "s/DB_REP_ENDPOINT/$RDS_DB_ENDPOINT/g" $EC2_USERDATA_FILE_1
sed -i "s/DB_REP_PASSWORD/$DB_MASTER_PASSWORD/g" $EC2_USERDATA_FILE_1
AWS_EC2_INSTANCE_ONE_ID=$(aws ec2 run-instances --image-id ami-0fbec3e0504ee1970 --instance-type t2.micro --subnet-id $SUBNET_PUBLIC_ID \
--security-group-ids $VPC_SG_SSH_HTTP --associate-public-ip-address --key-name $ENDAVA_KEY_PAIR \
--user-data file://$EC2_USERDATA_FILE_1 --query 'Instances[0].InstanceId' --output text)
echo "First EC2 instance ($AWS_EC2_INSTANCE_ONE_ID) is created!"

# Creating second EC2 for LB
wget $EC2_USERDATA_TEMPLETE_URL -O $EC2_USERDATA_FILE_2
sed -i "s/DB_REP_ENDPOINT/$RDS_DB_ENDPOINT/g" $EC2_USERDATA_FILE_2
sed -i "s/DB_REP_PASSWORD/$DB_MASTER_PASSWORD/g" $EC2_USERDATA_FILE_2
AWS_EC2_INSTANCE_TWO_ID=$(aws ec2 run-instances --image-id ami-0fbec3e0504ee1970 --instance-type t2.micro --subnet-id $SUBNET_PUBLIC_LB_ID \
--security-group-ids $VPC_SG_SSH_HTTP --associate-public-ip-address --key-name $ENDAVA_KEY_PAIR \
--user-data file://$EC2_USERDATA_FILE_2 --query 'Instances[0].InstanceId' --output text)
echo "Second EC2 instance ($AWS_EC2_INSTANCE_TWO_ID) is created!"


### 07. Creating Load Balancer Web Application
# Used script from here - https://cloudaffaire.com/how-to-create-an-application-load-balancer-using-aws-cli/
echo "07. Creating Load Balancer Web Application"
echo "---------------------"

## Create the application load balancer
AWS_ALB_ARN=$(aws elbv2 create-load-balancer \
--name my-application-load-balancer  \
--subnets $SUBNET_PUBLIC_ID $SUBNET_PUBLIC_LB_ID \
--security-groups $VPC_SG_SSH_HTTP \
--query 'LoadBalancers[0].LoadBalancerArn' \
--output text)
 
## Check the status of load balancer
aws elbv2 describe-load-balancers \
--load-balancer-arns $AWS_ALB_ARN \
--query 'LoadBalancers[0].State.Code' \
--output text

echo "Waiting 1 minute... Load Balancer to be ready."
sleep 60 
echo "Waiting 1 minute... Load Balancer to be ready."
sleep 60 

## Once the ALB status is active, get the DNS name for your ALB
AWS_ALB_DNS=$(aws elbv2 describe-load-balancers \
--load-balancer-arns $AWS_ALB_ARN \
--query 'LoadBalancers[0].DNSName' \
--output text) &&
echo $AWS_ALB_DNS
 
## Create the target group for your ALB
AWS_ALB_TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
--name my-alb-targets \
--protocol HTTP --port 80 \
--vpc-id $VPC_ID \
--query 'TargetGroups[0].TargetGroupArn' \
--output text)
 
## Register both the instances in the target group
aws elbv2 register-targets --target-group-arn $AWS_ALB_TARGET_GROUP_ARN  \
--targets Id=$AWS_EC2_INSTANCE_ONE_ID Id=$AWS_EC2_INSTANCE_TWO_ID
 
## Create a listener for your load balancer with a default rule that forwards requests to your target group
AWS_ALB_LISTNER_ARN=$(aws elbv2 create-listener --load-balancer-arn $AWS_ALB_ARN \
--protocol HTTP --port 80  \
--default-actions Type=forward,TargetGroupArn=$AWS_ALB_TARGET_GROUP_ARN \
--query 'Listeners[0].ListenerArn' \
--output text)

echo "Waiting 1 minute... Load Balancer to be ready."
sleep 60 
 
## Verify the health of the registered targets for your target group
aws elbv2 describe-target-health --target-group-arn $AWS_ALB_TARGET_GROUP_ARN
 
## Or curl your ALB DNS name repeatedly from your console
curl $AWS_ALB_DNS/SamplePage.php

### 08. Creating CloudWatch for EC2, DB RDS and Load Balancer
# Used script from here - https://github.com/swoodford/aws/blob/master/cloudwatch-create-alarms.sh
echo "08. Creating CloudWatch for EC2, DB RDS and Load Balancer"
echo "---------------------"

# Load Balancer Unhealthy Host Check
aws cloudwatch put-metric-alarm --alarm-name "Load Balalncer Unhealthy Host Check" --alarm-description "Load Balancer Unhealthy Host Detected" \
--metric-name "UnHealthyHostCount" --namespace "AWS/ELB" --statistic "Sum" --period 60 --threshold 0 \
--comparison-operator "GreaterThanThreshold" --dimensions Name=LoadBalancerName,Value=my-application-load-balancer --evaluation-periods 3 --alarm-actions "$ALARMACTION" --profile default
echo "Load Balancer Unhealthy Host Alarm Set"

# Load Balancer High Latency Check
aws cloudwatch put-metric-alarm --alarm-name "Load Balancer LB High Latency" --alarm-description "$Load Balancer High Latency" \
--metric-name "Latency" --namespace "AWS/ELB" --statistic "Average" --period 60 --threshold 15 --comparison-operator "GreaterThanThreshold" \
--dimensions Name=LoadBalancerName,Value=my-application-load-balancer --evaluation-periods 2 --alarm-actions "$ALARMACTION" --profile default
echo "Load Balancer High Latency Alarm Set"

# EC2 CPU Check
aws cloudwatch put-metric-alarm --alarm-name "First EC2 CPU Check" --alarm-description "First EC2 CPU usage >90% for 5 minutes" \
--namespace "AWS/EC2" --dimensions Name=InstanceId,Value=$AWS_EC2_INSTANCE_ONE_ID --metric-name "CPUUtilization" --statistic "Average" \
--comparison-operator "GreaterThanThreshold" --unit "Percent" --period 60 --threshold 90 --evaluation-periods 5 --alarm-actions "$ALARMACTION" --profile default
echo "First EC2 CPU Check Alarm Set"

# EC2 Status Check
aws cloudwatch put-metric-alarm --alarm-name "First EC2 Status Check" --alarm-description "First EC2 Status Check Failed for 5 minutes" \
--namespace "AWS/EC2" --dimensions Name=InstanceId,Value=$AWS_EC2_INSTANCE_ONE_ID --metric-name "StatusCheckFailed" --statistic "Maximum" \
--comparison-operator "GreaterThanThreshold" --unit "Count" --period 60 --threshold 0 --evaluation-periods 5 --alarm-actions "$ALARMACTION" --profile default
echo "First EC2 Status Check Alarm Set"

# EC2 CPU Check
aws cloudwatch put-metric-alarm --alarm-name "Second EC2 CPU Check" --alarm-description "First EC2 CPU usage >90% for 5 minutes" \
--namespace "AWS/EC2" --dimensions Name=InstanceId,Value=$AWS_EC2_INSTANCE_TWO_ID --metric-name "CPUUtilization" --statistic "Average" \
--comparison-operator "GreaterThanThreshold" --unit "Percent" --period 60 --threshold 90 --evaluation-periods 5 --alarm-actions "$ALARMACTION" --profile default
echo "Second EC2 CPU Check Alarm Set"

# EC2 Status Check
aws cloudwatch put-metric-alarm --alarm-name "Second EC2 Status Check" --alarm-description "First EC2 Status Check Failed for 5 minutes" \
--namespace "AWS/EC2" --dimensions Name=InstanceId,Value=$AWS_EC2_INSTANCE_TWO_ID --metric-name "StatusCheckFailed" --statistic "Maximum" \
--comparison-operator "GreaterThanThreshold" --unit "Count" --period 60 --threshold 0 --evaluation-periods 5 --alarm-actions "$ALARMACTION" --profile default
echo "Second EC2 Status Check Alarm Set"

# Database CPU Check
aws cloudwatch put-metric-alarm --alarm-name "DB CPU Check" --alarm-description "Database CPU usage >90% for 5 minutes" \
--metric-name "CPUUtilization" --namespace "AWS/RDS" --statistic "Average" --unit "Percent" --period 60 --threshold 90 --comparison-operator "GreaterThanThreshold" \
--dimensions Name=DBInstanceIdentifier,Value=$RDS_DB_ENDPOINT --evaluation-periods 5 --alarm-actions "$ALARMACTION" --profile default
echo "Database CPU Check Alarm Set"

# Database Memory Usage Check
aws cloudwatch put-metric-alarm --alarm-name "DB Mem Check" --alarm-description "Database Freeable Memory < 200 MB for 5 minutes" \
--metric-name "FreeableMemory" --namespace "AWS/RDS" --statistic "Average" --unit "Bytes" --period 60 --threshold "200000000" --comparison-operator "LessThanThreshold" \
--dimensions Name=DBInstanceIdentifier,Value=$RDS_DB_ENDPOINT --evaluation-periods 5 --alarm-actions "$ALARMACTION" --profile default
echo "Database Memory Usage Alarm Set"

# Database Available Storage Space Check
aws cloudwatch put-metric-alarm --alarm-name "DB Storage Check" --alarm-description "Database Available Storage Space < 200 MB" \
--metric-name "FreeStorageSpace" --namespace "AWS/RDS" --statistic "Average" --unit "Bytes" --period 60 --threshold "200000000" --comparison-operator "LessThanThreshold" \
--dimensions Name=DBInstanceIdentifier,Value=$RDS_DB_ENDPOINT --evaluation-periods 1 --alarm-actions "$ALARMACTION" --profile default
echo "Database Available Storage Space Alarm Set"

##### TO DO #####
### 09. Creating fail-over for all service
#echo "09. Creating fail-over for EC2, DB and Load Balancer"
#echo "---------------------"

#Region=eu-west-2
#ALARMACTION="arn:aws:automate:$Region:ec2:recover"
#InstanceID=i-0667d27a834d826ab

#aws cloudwatch put-metric-alarm --alarm-name "EC2 - Status Check Failed - $InstanceID" --metric-name StatusCheckFailed_System \
#--namespace AWS/EC2 --statistic Maximum --dimensions Name=InstanceId,Value="$InstanceID" --unit Count --period 60 --evaluation-periods 1 \
#--threshold 1 --comparison-operator GreaterThanThreshold --alarm-actions "$ALARMACTION" --output=json --profile default --region $Region
		
