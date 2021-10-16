# Package our image on a Docker Container

References,
https://github.com/yogeshraheja/helloworld/blob/master/helloworld.js
https://github.com/yogeshraheja/helloworld/blob/master/package.json
https://github.com/yogeshraheja/helloworld/blob/master/Dockerfile
https://github.com/yogeshraheja/EffectiveDevOpsTemplates/blob/master/ecr-repository-cf-template.py
https://github.com/yogeshraheja/EffectiveDevOpsTemplates/blob/master/ecs-cluster-cf-template.py
https://github.com/yogeshraheja/EffectiveDevOpsTemplates/blob/master/helloworld-ecs-alb-cf-template.py
https://github.com/yogeshraheja/EffectiveDevOpsTemplates/blob/master/helloworld-ecs-service-cf-template.py
https://github.com/yogeshraheja/EffectiveDevOpsTemplates/blob/master/helloworld-codebuild-cf-template.py
https://raw.githubusercontent.com/yogeshraheja/EffectiveDevOpsTemplates/master/helloworld-ecs-service-cf-template.py
https://github.com/yogeshraheja/EffectiveDevOpsTemplates/blob/master/helloworld-codepipeline-cf-template.py

## Services to use
- Docker
- EC2
- ECS
- ALB
- CodeBuild
- CodePipeline

## Docker Installation
Documentation for docker installation [here](./DockerInstallationOnUbuntu.md)

## Application dockerization
Reference,
- official AWS Docker image. You can read more about this at http://amzn.to/2jnmklF.

Steps
- Pull alphine image from docker registry
- Run a container
- Search the image to be used on cli or web (https://hub.docker.com/_/node/.)
- Create a Dockerfile on helloworld project, on "dockerized" branch
- Build the image
- Run a docker from the created image
- Validate in logs container is running and using curl
- Kill the container

Detail [here](./DockerizingApplication.md)

## ECS

In a general way we require,
- Create a Registry
- Upload the docker image
- Create a ECS Cluster
- Create a Load balancer
- Create a Container 
  - Using the Image from the Registry and deploying the image on the ECS Cluster
  - Test the Container using the Load balancer

Next we can see deail step by step,

### Create a ECR repo

Steps,
- Create the Cloudformation script for the Registry 
- Create the Registry
- Get the exported variables of the stack

```js
%> cat ecr-repository-cf-template.py
%> python ecr-repository-cf-template.py > ecr-repository.yaml
%> aws cloudformation create-stack \
    --stack-name helloworld-ecr \
    --capabilities CAPABILITY_IAM \
    --template-body file://ecr-repository.yaml \
    --parameters \ ParameterKey=RepoName,ParameterValue=helloworld

%> aws ecr describe-repositories
{
    "repositories": [
        {
            "registryId": "094507990803",
            "repositoryName": "helloworld",
            "repositoryArn": "arn:aws:ecr:us-east-1:094507990803:repository/helloworld",
            "createdAt": 1536345671.0,
            "repositoryUri": "094507990803.dkr.ecr.us-east-1.amazonaws.com/helloworld"
        }
    ]
}

%> aws cloudformation list-exports
```

### Upload the image to ECR

Steps,
- Login to ECR
- Tag the image
- Push the image to the Registry
- Validate image is on the Registry

```js
%> eval "$(aws ecr get-login --region us-east-1 --no-include-email )"

%> cd helloworld

# Get url from "aws ecr describe-repositories" on repositoryUri, in example "094507990803.dkr.ecr.us-east-1.amazonaws.com/helloworld"
%> docker tag helloworld:latest 094507990803.dkr.ecr.us-east-1.amazonaws.com/helloworld:latest

%> docker push 094507990803.dkr.ecr.us-east-1.amazonaws.com/helloworld:latest

%> aws ecr describe-images --repository-name helloworld
{
    "imageDetails": [
        {
            "imageSizeInBytes": 265821145,
            "imageDigest": "sha256:95906ec13adf9894e4611cd37c8a06569964af0adbb035fcafa6020994675161",
            "imageTags": [
                "latest"
            ],
            "registryId": "094507990803",
            "repositoryName": "helloworld",
            "imagePushedAt": 1536346218.0
        }
    ]
}
```

### Creation of the ECS Cluster
ECS service provides an orchestration layer. That orchestration layer is in charge of managing the life cycle of containers, including upgrading or downgrading and scaling your containers up or down. The orchestration layer also distributes all containers for every service across all instances of the cluster optimally. Finally, it also exposes a discovery mechanism that interacts with other services such as ALB and ELB to register and deregister containers.

Instead, we are using an ECS- optimized AMI (you can read more about this at http://amzn.to/2jX0xVu) that lets us use the UserData field to configure the ECS service, and then starting it.

Containers, through the intermediary of their task definitions, set a requirement for CPU and memory. They will require, for example, 1024 CPU units, which represents one core, and 256 memory units, which means 256 MB of RAM. If the ECS instances are close to being filled up on one of those two constraints, the ECS Auto Scaling Group needs to add more instances:

ECS distribution of new containers on existing ECS instances
![ECS distribution](./imgs/ECS01.png)

Steps,
- Create Troposphere template for the **ECS** cluster and convert to CloudFormation template
- Get VPCId and subnets for default VPC
- Create the cluster
- Create Troposphere template for the **ALB** and convert to CloudFormation template
- Create the ALB

```js
%> cat ecs-cluster-cf-template.py
...
from troposphere import (
...
    ec2
)
from troposphere.autoscaling import (
    AutoScalingGroup,
    LaunchConfiguration,
    ScalingPolicy
)
from troposphere.cloudwatch import (
    Alarm,
    MetricDimension
)
from troposphere.ecs import Cluster
...
t.add_resource(Cluster(
    'ECSCluster',
))
t.add_resource(Role(
    'EcsClusterRole',
    ManagedPolicyArns=[
        'arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM',
        'arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly',
        'arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role',
        'arn:aws:iam::aws:policy/CloudWatchFullAccess'
    ],
    AssumeRolePolicyDocument={
        'Version': '2012-10-17',
        'Statement': [{
            'Action': 'sts:AssumeRole',
            'Principal': {'Service': 'ec2.amazonaws.com'},
            'Effect': 'Allow',
        }]
    }
))
...
t.add_resource(AutoScalingGroup(
    'ECSAutoScalingGroup',
    DesiredCapacity='1',
    MinSize='1',
    MaxSize='5',
    VPCZoneIdentifier=Ref("PublicSubnet"),
    LaunchConfigurationName=Ref('ContainerInstances'),
))

states = {
    "High": {
        "threshold": "75",
        "alarmPrefix": "ScaleUpPolicyFor",
        "operator": "GreaterThanThreshold",
        "adjustment": "1"
    },
    "Low": {
        "threshold": "30",
        "alarmPrefix": "ScaleDownPolicyFor",
        "operator": "LessThanThreshold",
        "adjustment": "-1"
    }
}

for reservation in {"CPU", "Memory"}:
    for state, value in states.items(): #.iteritems():
        t.add_resource(Alarm(
            "{}ReservationToo{}".format(reservation, state),
            AlarmDescription="Alarm if {} reservation too {}".format(
                reservation,
                state),
            Namespace="AWS/ECS",
            MetricName="{}Reservation".format(reservation),
            Dimensions=[
                MetricDimension(
                    Name="ClusterName",
                    Value=Ref("ECSCluster")
                ),
            ],
            Statistic="Average",
            Period="60",
            EvaluationPeriods="1",
            Threshold=value['threshold'],
            ComparisonOperator=value['operator'],
            AlarmActions=[
                Ref("{}{}".format(value['alarmPrefix'], reservation))]
        ))
        t.add_resource(ScalingPolicy(
            "{}{}".format(value['alarmPrefix'], reservation),
            ScalingAdjustment=value['adjustment'],
            AutoScalingGroupName=Ref("ECSAutoScalingGroup"),
            AdjustmentType="ChangeInCapacity",
        ))

%> python ecs-cluster-cf-template.py > ecs-cluster.yaml

%> aws ec2 describe-vpcs --query 'Vpcs[].VpcId' 
[
    "vpc-e2f5139f",
]
%> aws ec2 describe-subnets --query 'Subnets[].SubnetId' 
[
    "subnet-29984808",
    "subnet-67558238",
    "subnet-e3445ddd",
    "subnet-6a0c9627",
    "subnet-586be756",
    "subnet-5ec70d38"
]

%> aws cloudformation create-stack \
    --stack-name staging-cluster \
    --capabilities CAPABILITY_IAM \
    --template-body file://ecs-cluster.yaml \
    --parameters \             
    ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS \     
    ParameterKey=VpcId,ParameterValue=vpc-e2f5139f \
    ParameterKey=PublicSubnet,ParameterValue=subnet-29984808\\,subnet-67558238\\,subnet-e3445ddd\\,subnet-6a0c9627\\,subnet-586be756\\,subnet-5ec70d38
```
**ALB**

```js
%> cat helloworld-ecs-alb-cf-template.py
...
t.add_resource(elb.LoadBalancer(
    "LoadBalancer",
    Scheme="internet-facing",
    Subnets=Split(
        ',',
        ImportValue(
            Join("-",
                 [Select(0, Split("-", Ref("AWS::StackName"))),
                  "cluster-public-subnets"]
                 )
        )
    ),
    SecurityGroups=[Ref("LoadBalancerSecurityGroup")],
))

t.add_resource(elb.TargetGroup(
    "TargetGroup",
    DependsOn='LoadBalancer',
    HealthCheckIntervalSeconds="20",
    HealthCheckProtocol="HTTP",
    HealthCheckTimeoutSeconds="15",
    HealthyThresholdCount="5",
    Matcher=elb.Matcher(
        HttpCode="200"),
    Port=3000,
    Protocol="HTTP",
    UnhealthyThresholdCount="3",
    VpcId=ImportValue(
        Join(
            "-",
            [Select(0, Split("-", Ref("AWS::StackName"))),
                "cluster-vpc-id"]
        )
    ),
))
...

%> python helloworld-ecs-alb-cf-template.py > helloworld-ecs-alb.yaml

%> aws cloudformation create-stack \
    --stack-name staging-alb \
    --capabilities CAPABILITY_IAM \
    --template-body file://helloworld-ecs-alb.yaml
{
    "StackId": "arn:aws:cloudformation:us-east-        
     1:094507990803:stack/staging-alb/4929fee0-b2d4-11e8-825f-
     50fa5f2588d2"
}
```

**Container** or ECS Service resource

Steps,
- Create Troposphere template for the **ECS Service** and convert to CloudFormation template
- Create the ECS Service
- Get DNS Name from the Cluster
- Test the deployment

```js
%> cat helloworld-ecs-service-cf-template.py
from troposphere.ecs import (
    TaskDefinition,
    ContainerDefinition
)
...
t.add_resource(TaskDefinition(
    "task",
    ContainerDefinitions=[
        ContainerDefinition(
            Image=Join("", [
                Ref("AWS::AccountId"),
                ".dkr.ecr.",
                Ref("AWS::Region"),
                ".amazonaws.com",
                "/",
                ImportValue("helloworld-repo"),
                ":",
                Ref("Tag")]),
            Memory=32,
            Cpu=256,
            Name="helloworld",
            PortMappings=[ecs.PortMapping(
                ContainerPort=3000)]
        )
    ],
))
...
t.add_resource(ecs.Service(
    "service",
    Cluster=ImportValue(
        Join(
            "-",
            [Select(0, Split("-", Ref("AWS::StackName"))),
                "cluster-id"]
        )
    ),
    DesiredCount=1,
    TaskDefinition=Ref("task"),
    LoadBalancers=[ecs.LoadBalancer(
        ContainerName="helloworld",
        ContainerPort=3000,
        TargetGroupArn=ImportValue(
            Join(
                "-",
                [Select(0, Split("-", Ref("AWS::StackName"))),
                    "alb-target-group"]
            ),
        ),
    )],
    Role=Ref("ServiceRole")
))
...

%> python helloworld-ecs-service-cf-template.py > helloworld-ecs-service.yaml

%> aws cloudformation create-stack \
    --stack-name staging-helloworld-service \
    --capabilities CAPABILITY_IAM \
    --template-body file://helloworld-ecs-service.yaml \
    --parameters ParameterKey=Tag,ParameterValue=latest

%> aws cloudformation describe-stacks \
    --stack-name staging-alb \
    --query 'Stacks[0].Outputs'
[
    {
        "Description": "TargetGroup",
        "ExportName": "staging-alb-target-group",
        "OutputKey": "TargetGroup",
        "OutputValue": "arn:aws:elasticloadbalancing:us-east-1:094507990803:targetgroup/stagi-Targe-ZBW30U7GT7DX/329afe507c4abd4d"
    },
    {
        "Description": "Helloworld URL",
        "OutputKey": "URL",
        "OutputValue": "http://stagi-LoadB-122Z9ZDMCD68X-1452710042.us-east-1.elb.amazonaws.com:3000"
    }
]

%> curl http://stagi-LoadB-122Z9ZDMCD68X-1452710042.us-east-1.elb.amazonaws.com:3000
Hello World

```

## Updating deployment on ECS containers

Steps,
- Make the changes in the helloworld code
- Log in to the ecr registry
- Build your Docker container
- Pick a new unique tag, and use it to tag your image "foobar"
- Push the image to the ecr repository
- Update the ECS service CloudFormation stack

Instances should be destroyed and recreated on the current TargetGroup using the new tag of the image

```js
%> eval "$(aws ecr get-login --region us-east-1 --no-include- email)" 

%> docker build -t helloworld 

%> docker tag helloworld 094507990803.dkr.ecr.us-east-1.amazonaws.com/helloworld:foobar

%> docker push 094507990803.dkr.ecr.us-east-1.amazonaws.com/helloworld:foobar

%> aws cloudformation update-stack \
    --stack-name staging-helloworld-service \
    --capabilities CAPABILITY_IAM \
    --template-body file://helloworld-ecs-service.yaml \
    --parameters \ 
      ParameterKey=Tag,ParameterValue=foobar

```