#!/bin/bash

if [ $# -lt 1 ]
then
        echo "Usage : $0 option"
        echo "Posible obtions: "
        echo "1: jenkins"
        echo "2: stating"
        echo "3: pro"
        echo "4: jenkins+stating"
        echo "9: all"
        exit
fi


startJenkins(){
aws cloudformation create-stack \
      --capabilities CAPABILITY_IAM \
      --stack-name jenkins \
      --template-body file://jenkins-cf.yaml \
      --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS \
                   ParameterKey=HostedZone,ParameterValue=esausi.com
}

waitJenkins(){
aws cloudformation wait stack-create-complete \
      --stack-name jenkins
}

startStaging(){
aws cloudformation create-stack \
      --capabilities CAPABILITY_IAM \
      --stack-name staging \
      --template-body file://nodeserver-cf.yaml \
      --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS \
                   ParameterKey=HostedZone,ParameterValue=esausi.com \
                   ParameterKey=InstanceDNSRecordName,ParameterValue=nodeserver.stating
}

waitStaging(){
aws cloudformation wait stack-create-complete \
      --stack-name staging
}

startPro(){
aws cloudformation create-stack \
      --capabilities CAPABILITY_IAM \
      --stack-name production \
      --template-body file://nodeserver-cf.yaml \
      --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS \
                   ParameterKey=HostedZone,ParameterValue=esausi.com \
                   ParameterKey=InstanceDNSRecordName,ParameterValue=nodeserver.pro
}

waitPro(){
aws cloudformation wait stack-create-complete \
      --stack-name production
}

case "$1" in

1) echo "Stating jenkins"
   startJenkins
   waitJenkins
   echo "Started ..."

;;

2) echo "Starting staging"
   startStaging
   waitStaging
   echo "Started ..."

;;

3) echo "Starting  pro"
   startPro
   waitPro
   echo "Started ..."

;;

4) echo "Starting jenkins + staging"
   startJenkins
   startStaging
   waitStaging
   waitJenkins
   echo "Started ..."

;;

9) echo "Starting all"
   startJenkins
   startStaging
   startPro
   waitStaging
   waitJenkins
   waitPro
   echo "Started ..."
   
;;

*) echo "Invalid option"

;;

esac
