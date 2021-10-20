# ECS deployment using pipeline

Techinologies to use,
- CloudFormation
- ECS
- CodeBuild (Automating containers creation)
- CodePipeline
- CodeDeploy

It was reused all CF scripts an Shell scripts from example [ECS-ALB-DockerImage](./12ECS-ALB-DockerImage)

## Environment setup
Previos steps,
- Creation of Staging environment

New steps, creation of Production environment,
- Create new ECS Cluster for production
- Create new ALB for production
- Create new Service for production
- Test production deployment

All automated on [startEnv.sh](./startEnv.sh)

```js
%> python ecs-cluster-cf-template.py > ecs-cluster.yaml

%> aws cloudformation create-stack \
    --stack-name production-cluster \
    --capabilities CAPABILITY_IAM \
    --template-body file://ecs-cluster.yaml \
    --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS \
                 ParameterKey=VpcId,ParameterValue=vpc-e2f5139f \
                 ParameterKey=PublicSubnet,ParameterValue=subnet-29984808\\,subnet-67558238\\,subnet-e3445ddd\\,subnet-6a0c9627\\,subnet-586be756\\,subnet-5ec70d38

%> aws cloudformation wait stack-create-complete --stack-name production-cluster

%> aws cloudformation create-stack \
    --stack-name production-alb \
    --capabilities CAPABILITY_IAM \
    --template-body file://helloworld-ecs-alb.yaml

%> aws cloudformation wait stack-create-complete --stack-name production-alb

%> aws cloudformation create-stack \
    --stack-name production-helloworld-service \
    --capabilities CAPABILITY_IAM \
    --template-body file://helloworld-ecs-service.yaml \
    --parameters ParameterKey=Tag,ParameterValue=latest

%> aws cloudformation wait stack-create-complete --stack-name production-helloworld-service

#Test
%> serviceURL=$(aws cloudformation describe-stacks \
    --stack-name production-alb \
    --query 'Stacks[0].Outputs' | grep us-east-1.elb.amazonaws.com:3000 | awk 'BEGIN { FS = " " } ; { print $2}' | sed 's/\"//' | sed 's/\"//' | sed 's/,//')
#echo "aws cloudformation describe-stacks --stack-name production-alb --query 'Stacks[0].Outputs' | grep us-east-1.elb.amazonaws.com:3000 | awk 'BEGIN { FS = " " } ; { print $2}' | sed 's/\"//' | sed 's/,//'"
%> echo "curl $serviceURL"
%> curl $serviceURL

```

## Automating the creation of containers with CodeBuild

Instead of continue using public npm image and upload it to the ECR, we are going to build a new image using CodeBuild and this is the image we will upload to ECR.

CodeBuild
Uses a **buildspec** file for the image creation, this file has sections,
- pre_build:  Steps previous to build the image
- build:      Image building
- post_build: Push image to ECR
- artifacts:  File to upload to S3

```js
%> python helloworld-codebuild-cf-template.py > helloworld-codebuild.yaml

%> aws cloudformation create-stack \
    --stack-name helloworld-codebuild \
    --capabilities CAPABILITY_IAM \
    --template-body file://helloworld-codebuild.yaml

%> aws cloudformation wait stack-create-complete --stack-name helloworld-codebuild

%> aws cloudformation delete-stack --stack-name helloworld-codebuild
%> aws cloudformation wait stack-delete-complete --stack-name helloworld-codebuild
```