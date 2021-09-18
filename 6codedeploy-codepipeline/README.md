# Using CodeDeploy and CodePipeline
Trying to answer the questions for clarify use of CodeDeploy and CodePipeline
- What are we trying to deploy?   CodePipeline
- Where are we trying to deploy?  CodeDeploy, conf file
- How can we deploy it?           CodeDeploy, hooks on appspec.yml file

**CodeDeploy** is an agent and configuration files and helpers which help to control deployment and status validation of our application on an EC2 instance
**CodePipeline** is a fully managed service dedicated to creating delivery pipelines, integrated with AWS ecosystem, it means CodeDeploy, IAM. Thanks to its API, a number of services can be integrated into your pipelines, including Jenkins and Github.

## Setup
In order to use CodeDeploy, EC2 instance require to use CodeDeploy Agent, an executable from S3.
This could be done using a custom Ansible library, which should be on /usr/share/my_modules or root of our ansible repo

Steps,
- On root create "library" dir (ansible-pull-gitrepo> git checkout feature/add-codedeploy)
- Download binary
- Edit ansible.cfg and specify the location of the library
- Create a codedeploy role: This role is going to prepare the EC2 instance with NodeJS and CodeDeploy Agent
- Copy Troposphere template and customize
- Generate CloudFormation script and execute, by this we have time EC instance with codedeploy-agent running
- Generate Codedeploy IAM service role: this give permisions to Codedeploy service (Principal Service codedeploy.amazonaws.com), this is going to be used by the "Application deployment" on CodeDeploy
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

## Setup instance deployment - CodeDeploy
Creating the application in Codedeploy allows us to define where our newly created application will be deployed.
In previous example we were using ansible to start/stop de application, here we are going to use Codedeploy
Codedeploy requires a series of scripts for treat our app as a service. Codedeploy agent is going to manage
our application as a service using the scripts, going through this sequence of events
  Appication Stop -> Download Bundle -> BeforeInstall -> Install -> AfterInstall -> Application Start -> Validate Service

Codedeploy hooks
Custom acction to be executed on the previous list of events, are defined on the appspec.yml
We define 3 scripts for: start, stop and validate (check if deployment was successful)

**Codedeploy lifecycle**
Codedeploy agent is going to manage our deployment with the events
- Download application package and decompress it
- Run stop script
- Copy application and upstart script
- Run start script
- Run validate script validating everything is working as expected


**Implementation steps,**
- AWS Console -> CodeDeploy Console -> Get started now -> Custom deployment -> Skip walkthrough
- Create "hellonewworld" Application, Compute platform "EC2/On-premises" -> Create application
- Create a Deployment group (Environment)
  - Deoployment group name: staging
  - Service role: arn:aws:iam::309135946640:role/CodeDeployServiceRole
  - Deployment type: In-place
  - Environment configuration: Amazon EC2 instances; This is going to link EC2 instances with this "Deployment group"
    - Key: aws:cloudformation:stack-name, Value: helloworld-staging
  - Deployment configuration: CodeDeployDefault.OneAtATime
  - Load balancer: none
  - Rollback: Roll back when a deployment fails
  -> Create deployment group
- Create Codedeploy script on App repo "appspec.yml"  (helloworld> git checkout helloworld-codedeploy)
- Create service configuration on scripts/helloworld.conf
- Add Codedeploy hook scripts for stop, start, validate on scripts dir, add execution permission

```js
%> cat appspec.yml
version: 0.0
os: linux
files:
  - source: /helloworld.js
    destination: /usr/local/helloworld/
  - source: /scripts/helloworld.conf
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

%> cat scripts/helloworld.conf
description "Hello world Deamon"

# Start when the system is ready to do networking.
start on started elastic-network-interfaces

# Stop when the system is on its way down.
stop on shutdown

respawn
script
    exec su --session-command="/usr/bin/node /usr/local/helloworld/helloworld.js" ec2-user
end script

%> cat scritps/start.sh
#!/bin/sh
start helloworld

%> cat scripts/stop.sh
#!/bin/sh

[[ -e /etc/init/helloworld.conf ]] \
   && status helloworld | \
      grep -q '^ĥelloworld start/running, process' \
   && [[ $? -eq 0 ]] \
   && stop helloworld || echo "Application not started"

%> cat scripts/validate.sh
#!/bin/sh
curl -I localhost:3000

%> chmod a+x scripts/{start,stop,validate}.sh

```

## Setup Pipeline - CodePipeline

Out pipeline is going to be composed of these stages,
- Get code from github, package it and store on S3
- Test our application using Jenkins
- Take the package from S3 and deploy on Staging environment
- Validation step - On demand production deployment process for deploy to Production environment

This control for deploy to production use to be called Continous delivery pipeline, but when there are confidence on the process it can be aliminated and turn it into a fully automated pipeline.

For create a pipeline,
- Codepipeline Console -> Create Pipeline -> Name, Next
- Add source stage -> 
  - Select github (version 2)
  - Select connection or create new one (using github authentication)
  - Select project "helloworld"
  - Select branch name "helloworld-codedeploy" and Press Next
- Add build stage -> Because using NodeJS, no build required so, chose "Skip build stage" 
- Add deploy stage -> Deployment provider -> 
  - Select "Codedeploy"
  - Application name "hellonewworld"
  - Deploymemt group "staging" (previously created on CodeDeploy)

### Testing 

```js
%> curl http://nodeserver.esausi.com:3000/
Hello World
```

## Troubleshooting

**Error: Files copied but steps not started**
On file appspec.yml it is required root permissions for execute shell commands

**Solution**
Add "runas: root" instruction to every shell script execution

```js
%> cat appspec.yml
...
hooks:
  BeforeInstall:
    - location: scripts/stop.sh
      timeout: 30
      runas: root
...
```

**Error: On start.sh shell script, 'start command not found' message**
When launch AWS Codepipeline, on Deployments appears execution events but fails on "ApplicationStart" event, message 'start command not found'
helloworld.conf file on /etc/init is not working on AWS linux 2

**Solution**
On Linux AMI 2 it is required to add systemd daemon, detail on [systemd.md](./systemd.md) file

**Error: On changes push to repo, app is not showing changes on helloworld.js file even file was updated on EC2 instance**
Once reviewd instance and stop.sh shell script, command for stop app was wrong

**Solution**
Update stop.sh shell script with correct command also created setup.sh script for reload daemon information

```js
%> cat stop.sh
#!/bin/sh

[[ -e /etc/init/helloworld.conf ]] \
   && systemctl status helloworld-daemon | \
      grep -q '^active (running)' \
   && [[ $? -eq 0 ]] \
   && stop helloworld || echo "Application not started"

%> cat setup.sh
#!/bin/sh
#start helloworld
sudo systemctl daemon-reload

%> cat appspec.yml
version: 0.0
os: linux
files:
  - source: /helloworld.js
    destination: /usr/local/helloworld/
  - source: /scripts/helloworld-daemon.service
    destination: /etc/systemctl/system
hooks:
  BeforeInstall:
    - location: scripts/stop.sh
      timeout: 30
      runas: root
    - location: scripts/setup.sh
      timeout: 30
      runas: root
  ApplicationStart:
    - location: scripts/start.sh
      timeout: 30
      runas: root
  ValidateService:
    - location: scripts/validate.sh
```

## References
- https://www.shellhacks.com/systemd-service-file-example/
- https://docs.aws.amazon.com/codedeploy/latest/userguide/tutorials-github-upload-sample-revision.html
