#!/bin/bash

echo "Creating ECR Registry ..."
aws cloudformation create-stack \
    --stack-name helloworld-ecr-aws \
    --capabilities CAPABILITY_IAM \
    --template-body file://ecr-repository.yaml \
    --parameters ParameterKey=RepoName,ParameterValue=helloworld-aws
aws cloudformation wait stack-create-complete --stack-name helloworld-ecr-aws
echo "ECR Registry created ..."
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
    --template-body file://helloworld-ecs-alb.yaml \
    --parameters ParameterKey=HostedZone,ParameterValue=esausi.com \
                 ParameterKey=DnsPrefix,ParameterValue=staging 
aws cloudformation wait stack-create-complete --stack-name staging-alb
echo "ALB created ..."
echo ""

echo "**********************************************PRODUCTION****************************************************************"
echo "Creating cluster ..."
aws cloudformation create-stack \
    --stack-name production-cluster \
    --capabilities CAPABILITY_IAM \
    --template-body file://ecs-cluster.yaml \
    --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS \
                 ParameterKey=VpcId,ParameterValue=vpc-e2f5139f \
                 ParameterKey=PublicSubnet,ParameterValue=subnet-29984808\\,subnet-67558238\\,subnet-e3445ddd\\,subnet-6a0c9627\\,subnet-586be756\\,subnet-5ec70d38
aws cloudformation wait stack-create-complete --stack-name production-cluster
echo "Cluster created ..."
echo ""

echo "Creating ALB ..."
aws cloudformation create-stack \
    --stack-name production-alb \
    --capabilities CAPABILITY_IAM \
    --template-body file://helloworld-ecs-alb.yaml \
    --parameters ParameterKey=HostedZone,ParameterValue=esausi.com \
                 ParameterKey=DnsPrefix,ParameterValue=production 
aws cloudformation wait stack-create-complete --stack-name production-alb
echo "ALB created ..."
echo ""

echo "**********************************************PIPELINE****************************************************************"
echo "Creating codebuild ..."
aws cloudformation create-stack \
    --stack-name helloworld-codebuild \
    --capabilities CAPABILITY_IAM \
    --template-body file://helloworld-codebuild.yaml
aws cloudformation wait stack-create-complete --stack-name helloworld-codebuild
echo "CodeBuild created ..."

echo "Creating CodePipeline ..."
aws cloudformation create-stack \
    --stack-name helloworld-codepipeline \
    --capabilities CAPABILITY_NAMED_IAM \
    --template-body file://helloworld-codepipeline.yaml
aws cloudformation wait stack-create-complete --stack-name helloworld-codepipeline
echo "CodePipeline created ..."

echo "**********************************************TESTING THE SERVICE****************************************************************"

echo "NOT POSSIBLE NOW, NEEDS TO UPDATE CONNECTION TO GITHUB AND START THE PIPELINE!!!"
echo "ONCE DONE THIS, USE:"
echo "%> ./testEnv.sh"

