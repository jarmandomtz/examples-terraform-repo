#!/bin/bash

echo "**********************************************TESTING THE SERVICE****************************************************************"

echo "Testing Staging using ALB ..."
serviceURL=$(aws cloudformation describe-stacks \
    --stack-name staging-alb \
    --query 'Stacks[0].Outputs' | grep us-east-1.elb.amazonaws.com:3000 | awk 'BEGIN { FS = " " } ; { print $2}' | sed 's/\"//' | sed 's/\"//' | sed 's/,//')
#echo "aws cloudformation describe-stacks --stack-name staging-alb --query 'Stacks[0].Outputs' | grep us-east-1.elb.amazonaws.com:3000 | awk 'BEGIN { FS = " " } ; { print $2}' | sed 's/\"//' | sed 's/,//'"
echo "curl $serviceURL"
curl $serviceURL
echo "Testing Staging using DNS Zone ..."
serviceURLS="http://staging.esausi.com:3000"
echo "curl $serviceURLS"
curl $serviceURLS
echo "Staging Tests ended ..."


echo "Testing Production using ALB ..."
serviceURL=$(aws cloudformation describe-stacks \
    --stack-name production-alb \
    --query 'Stacks[0].Outputs' | grep us-east-1.elb.amazonaws.com:3000 | awk 'BEGIN { FS = " " } ; { print $2}' | sed 's/\"//' | sed 's/\"//' | sed 's/,//')
#echo "aws cloudformation describe-stacks --stack-name production-alb --query 'Stacks[0].Outputs' | grep us-east-1.elb.amazonaws.com:3000 | awk 'BEGIN { FS = " " } ; { print $2}' | sed 's/\"//' | sed 's/,//'"
echo "curl $serviceURL"
curl $serviceURL
echo "Testing Staging using DNS Zone ..."
serviceURLP="http://production.esausi.com:3000"
echo "curl $serviceURLP"
curl $serviceURLP
echo "Production Tests ended ..."

