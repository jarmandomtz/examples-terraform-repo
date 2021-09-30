#!/bin/bash
aws cloudformation delete-stack \
      --stack-name jenkins 

aws cloudformation delete-stack \
      --stack-name staging

aws cloudformation delete-stack \
      --stack-name production

echo "Deletion on progress ..."
aws cloudformation wait stack-delete-complete \
      --stack-name jenkins

aws cloudformation wait stack-delete-complete \
      --stack-name staging  

aws cloudformation wait stack-delete-complete \
      --stack-name production         
echo "Deletion completed ..."