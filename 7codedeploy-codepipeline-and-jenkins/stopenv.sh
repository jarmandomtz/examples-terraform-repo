#!/bin/sh
aws cloudformation delete-stack \
      --stack-name jenkins 

aws cloudformation delete-stack \
      --stack-name staging

echo "jenkins and staggin deletion on progress ..."
aws cloudformation wait stack-delete-complete \
      --stack-name jenkins

aws cloudformation wait stack-delete-complete \
      --stack-name staging      
echo "jenkins and staggin deletion finished ..."