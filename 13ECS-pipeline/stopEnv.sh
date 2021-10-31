#!/bin/bash

echo "**************************************PRODUCTION**************************************************"
#Cannot be deleted fist ALB, ecs-service uses an export defined on alb
echo "Deleting ECS Service ..."
aws cloudformation delete-stack --stack-name production-helloworld-ecs-service
aws cloudformation wait stack-delete-complete --stack-name production-helloworld-ecs-service
echo "ECS Service deleted "
echo " "

echo "Deleting ALB ..."
aws cloudformation delete-stack --stack-name production-alb
aws cloudformation wait stack-delete-complete --stack-name production-alb
echo "ALB deleted "
echo " "

echo "Deleting ECS Cluster ..."
aws cloudformation delete-stack --stack-name production-cluster
aws cloudformation wait stack-delete-complete --stack-name production-cluster
echo "ECS Cluster deleted "
echo " "

echo "**************************************STAGING**************************************************"
#Cannot be deleted fist ALB, ecs-service uses an export defined on alb
echo "Deleting ECS Service ..."
aws cloudformation delete-stack --stack-name staging-helloworld-ecs-service
aws cloudformation wait stack-delete-complete --stack-name staging-helloworld-ecs-service
echo "ECS Service deleted "
echo " "

echo "Deleting ALB ..."
aws cloudformation delete-stack --stack-name staging-alb
aws cloudformation wait stack-delete-complete --stack-name staging-alb
echo "ALB deleted "
echo " "

echo "Deleting ECS Cluster ..."
aws cloudformation delete-stack --stack-name staging-cluster
aws cloudformation wait stack-delete-complete --stack-name staging-cluster
echo "ECS Cluster deleted "
echo " "

echo "**************************************PIPELINE**************************************************"
#Cannot be deleted CodePipeline at the begining of all, It defines the Role used by CloudFormation for delete ECS Services and Stacks
echo "Deleting CodePipeline pipeline ..."
aws cloudformation delete-stack --stack-name helloworld-codepipeline
aws cloudformation wait stack-delete-complete --stack-name helloworld-codepipeline
echo "CodePipeline pipeline deleted ..."

echo "Deleting CodeBuild pipeline ..."
aws cloudformation delete-stack --stack-name helloworld-codebuild
aws cloudformation wait stack-delete-complete --stack-name helloworld-codebuild
echo "CodeBuild pipeline deleted ..."
echo " "

echo "**************************************ECR**************************************************"
#If ECR contains images, error occurs
#Resource handler returned message: "The repository with name 'helloworld' in registry with id '309135946640' 
#cannot be deleted because it still contains images (Service: Ecr, Status Code: 400, 
#Request ID: 9bfb6818-3987-4d39-8253-f42b5a1caa9a, Extended Request ID: null)" (RequestToken: 
#d175f13b-1797-6ac1-78af-0c9985dd226f, HandlerErrorCode: GeneralServiceException)

echo "Deleting images on ECR ..."
for i in $(aws ecr list-images --repository-name helloworld-aws | grep imageTag | awk '{ print $2}') 
do
  echo "Deleting $i ..."
  aws ecr batch-delete-image --repository-name helloworld-aws --image-ids imageTag=$i
  echo "$i deleted"
done
echo "ECR images deleted"
echo " "

echo "Deleting ECR ..."
aws cloudformation delete-stack --stack-name helloworld-ecr-aws
aws cloudformation wait stack-delete-complete --stack-name helloworld-ecr-aws
echo "ECR deleted "