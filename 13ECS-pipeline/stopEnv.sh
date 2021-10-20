#!/bin/bash
echo "**************************************PRODUCTION**************************************************"
echo "Deleting ECS Service ..."
aws cloudformation delete-stack --stack-name production-helloworld-service 
aws cloudformation wait stack-delete-complete --stack-name staging-helloworld-service
echo "ECS Service deleted "
echo " "

echo "Deleting ALB ..."
aws cloudformation delete-stack --stack-name staproductionging-alb 
aws cloudformation wait stack-delete-complete --stack-name staging-alb
echo "ALB deleted "
echo " "

echo "Deleting ECS Cluster ..."
aws cloudformation delete-stack --stack-name production-cluster 
aws cloudformation wait stack-delete-complete --stack-name staging-cluster
echo "ECS Cluster deleted "
echo " "

echo "**************************************STAGING**************************************************"
echo "Deleting ECS Service ..."
aws cloudformation delete-stack --stack-name staging-helloworld-service 
aws cloudformation wait stack-delete-complete --stack-name staging-helloworld-service
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

#If ECR contains images, error occurs
#Resource handler returned message: "The repository with name 'helloworld' in registry with id '309135946640' 
#cannot be deleted because it still contains images (Service: Ecr, Status Code: 400, 
#Request ID: 9bfb6818-3987-4d39-8253-f42b5a1caa9a, Extended Request ID: null)" (RequestToken: 
#d175f13b-1797-6ac1-78af-0c9985dd226f, HandlerErrorCode: GeneralServiceException)

echo "Deleting images on ECR ..."
for i in $(aws ecr list-images --repository-name helloworld | grep imageTag | awk '{ print $2}') 
do
  echo "Deleting $i ..."
  aws ecr batch-delete-image --repository-name helloworld --image-ids imageTag=$i
  echo "$i deleted"
done
echo "ECR images deleted"
echo " "

echo "Deleting ECR ..."
aws cloudformation delete-stack --stack-name helloworld-ecr 
aws cloudformation wait stack-delete-complete --stack-name helloworld-ecr

echo "ECR deleted "