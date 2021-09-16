# Using CodeDeploy and CodePipeline

## Setup
In order to use CodeDeploy, EC2 instance require to use CodeDeploy Agent, an executable from S3.
This could be done using a custom Ansible library, which should be on /usr/share/my_modules or root of our ansible repo

Steps,
- On root create "library" dir (ansible-pull-gitrepo> git checkout feature/add-codedeploy)
- Download binary
- Edit ansible.cfg and specify the location of the library
- Create a codedeploy role
- Copy Troposphere template and customize
- Generate CloudFormation script and execute, by this we have time EC instance with codedeploy-agent running
- Generate Codedeploy IAM service role
- Attach role policy "AWSCodeDeployRole" to provide proper permissions to the service role

```js
%> cd ansible
ansible %> mkdir library
ansible %> curl -L https://raw.githubusercontent.com/yogeshraheja/Effective-DevOps-with-AWS/master/Chapter05/ansible/library/aws_codedeploy > library/aws_codedeploy
ansible %> cat ansible.cfg
[defaults]
inventory = ./ec2.py
remote_user = ec2-user
become = True
become_method = sudo
become_user = root
nocows = 1
library = library

ansible %> cd roles
ansible/roles %> ansible-galaxy init codedeploy
- Role codedeploy was created successfully

ansible/roles %> cat codedeploy/tasks/main.yml
---
# tasks file for codedeploy
- name: Installs and starts the AWS CodeDeploy Agent
  aws_codedeploy:
    enable: yes

ansible/roles %> cd ..
ansible %> cat nodeserver.yml
---
- hosts: "{{ target | default('localhost') }}"
  become: yes
  roles:
    - nodejs
    - codedeploy

ansible %> cd ..
%> cat nodeserver-cf-template.py
...
ApplicationName = "nodeserver"
ApplicationPort = "3000"
...
#Create S3 Bucket Policy
t.add_resource(IAMPolicy(
    "Policy",
    PolicyName="AllowsS3",
    PolicyDocument=Policy(
        Statement=[
            Statement(
                Effect=Allow,
                Action=[Action("s3", "*")],
                Resource=["*"]
            )
        ]
    ),
    Roles=[Ref(Role)]
))
...

%> python nodeserver-cf-template.py > nodeserver-cf.yaml

%> aws cloudformation delete-stack \
      --stack-name helloworld-staging 

%> aws cloudformation wait stack-delete-complete \
      --stack-name helloworld-staging

%> aws cloudformation create-stack \
      --capabilities CAPABILITY_IAM \
      --stack-name helloworld-staging \
      --template-body file://nodeserver-cf.yaml \
      --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS \
                   ParameterKey=HostedZone,ParameterValue=esausi.com \
                   ParameterKey=InstanceDNSRecordName,ParameterValue=nodeserver

%> aws cloudformation wait stack-create-complete \
      --stack-name helloworld-staging

%> cat codedeploy-iam-servicerole.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
              "Service": [
                "codedeploy.amazonaws.com"
              ]
            },
            "Action": "sts:AssumeRole"
        }
    ]
}

%> aws iam detach-role-policy \
     --role-name CodeDeployServiceRole \
     --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole

%> aws iam delete-role \
     --role-name CodeDeployServiceRole 

%> aws iam create-role \
     --role-name CodeDeployServiceRole \
     --assume-role-policy-document file://codedeploy-iam-servicerole.json 

%> aws iam attach-role-policy \
     --role-name CodeDeployServiceRole \
     --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole

%> 
```

## Creating CodeDeploy Application (create env for deploy apps)
Creating the application in Codedeploy allows us to define where our newly created application will be deployed.

Steps,
- AWS Console -> CodeDeploy Console -> Get started now -> Custom deployment -> Skip walkthrough
- Create "hellonewworld" Application, Compute platform "EC2/On-premises" -> Create application
- Create a Deployment group (Environment)
  - Deoployment grou name: staging
  - Service role: rn:aws:iam::aws:policy/service-role/AWSCodeDeployRole
  - Deployment type: In-place
  - Environment configuration: Amazon EC2 instances
    - Key: aws:cloudformation:stack-name, Value: helloworld-staging
  - Deployment configuration: CodeDeployDefault.OneAtATime
  - Load balancer: none
  - Rollback: Roll back when a deployment fails
  -> Create deployment group
- Create Codedeploy script on App repo "appspec.yml"  (helloworld> git checkout helloworld-codedeploy)

```js
%> cat appspec.yml
version: 0.0
os: linux
files:
  - source: helloworld.js
    destination: /usr/local/helloworld/
  - source: scripts/helloworld.conf
    destination: /etc/init/
hooks:
  BeforeInstall:
    - location: scripts/stop.sh
      timeout: 30
  ApplicationStart:
    - location: scripts/start.sh
      timeout: 30
  ValidateService:
    - location: scripts/validate.sh

```

