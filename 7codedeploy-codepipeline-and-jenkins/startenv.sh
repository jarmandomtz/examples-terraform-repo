#!/bin/sh
aws cloudformation create-stack \
      --capabilities CAPABILITY_IAM \
      --stack-name jenkins \
      --template-body file://jenkins-cf.yaml \
      --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS \
                   ParameterKey=HostedZone,ParameterValue=esausi.com

aws cloudformation create-stack \
      --capabilities CAPABILITY_IAM \
      --stack-name staging \
      --template-body file://nodeserver-cf.yaml \
      --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS \
                   ParameterKey=HostedZone,ParameterValue=esausi.com \
                   ParameterKey=InstanceDNSRecordName,ParameterValue=nodeserver
echo "jenkins and staggin creation on progress ..."
aws cloudformation wait stack-create-complete \
      --stack-name staging
aws cloudformation wait stack-create-complete \
      --stack-name jenkins
echo "jenkins and staggin creation finished ..."