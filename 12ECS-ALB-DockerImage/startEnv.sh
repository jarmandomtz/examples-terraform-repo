#!/bin/bash

echo "Creating ECR Registry ..."
aws cloudformation create-stack \
    --stack-name helloworld-ecr \
    --capabilities CAPABILITY_IAM \
    --template-body file://ecr-repository.yaml \
    --parameters ParameterKey=RepoName,ParameterValue=helloworld
aws cloudformation wait stack-create-complete --stack-name helloworld-ecr
echo "Creating ECR Registry ..."
echo ""

echo "Uploading image to ECR ..."
eval "$(aws ecr get-login --region us-east-1 --no-include-email )"
#docker tag helloworld:latest 309135946640.dkr.ecr.us-east-1.amazonaws.com/helloworld:latest
docker push 309135946640.dkr.ecr.us-east-1.amazonaws.com/helloworld:latest
echo "Image uploaded ..."
echo ""

echo "**********************************************STAGING****************************************************************"
echo "Creating cluster ..."
aws cloudformation create-stack \
    --stack-name staging-cluster \
    --capabilities CAPABILITY_IAM \
    --template-body file://ecs-cluster.yaml \
    --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS \
                 ParameterKey=VpcId,ParameterValue=vpc-e2f5139f \
                 ParameterKey=PublicSubnet,ParameterValue=subnet-29984808\\,subnet-67558238\\,subnet-e3445ddd\\,subnet-6a0c9627\\,subnet-586be756\\,subnet-5ec70d38
aws cloudformation wait stack-create-complete --stack-name staging-cluster
echo "Cluster created ..."
echo ""

echo "Creating ALB ..."
aws cloudformation create-stack \
    --stack-name staging-alb \
    --capabilities CAPABILITY_IAM \
    --template-body file://helloworld-ecs-alb.yaml
aws cloudformation wait stack-create-complete --stack-name staging-alb
echo "ALB created ..."
echo ""

echo "Creating container ..."
aws cloudformation create-stack \
    --stack-name staging-helloworld-service \
    --capabilities CAPABILITY_IAM \
    --template-body file://helloworld-ecs-service.yaml \
    --parameters ParameterKey=Tag,ParameterValue=latest
aws cloudformation wait stack-create-complete --stack-name staging-helloworld-service
echo "Container created ..."
echo ""

echo "Testing ..."
serviceURL=$(aws cloudformation describe-stacks \
    --stack-name staging-alb \
    --query 'Stacks[0].Outputs' | grep us-east-1.elb.amazonaws.com:3000 | awk 'BEGIN { FS = " " } ; { print $2}' | sed 's/\"//' | sed 's/\"//' | sed 's/,//')
#echo "aws cloudformation describe-stacks --stack-name staging-alb --query 'Stacks[0].Outputs' | grep us-east-1.elb.amazonaws.com:3000 | awk 'BEGIN { FS = " " } ; { print $2}' | sed 's/\"//' | sed 's/,//'"
echo "curl $serviceURL"
curl $serviceURL
echo "Tests ended ..."
