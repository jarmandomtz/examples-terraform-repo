# Chapter 5 - Adding CI and CD

CodeDeploy: Let us decide hot the new code needs to be deployed to our EC2 instances
CodePipeline: Let us orchestrate the full life cycle of our app

Manual step to deploy code to production is called CD. Provides de ability to validate a build on staging environment before it gets deployed to production

Stack tech used
- github
- jenkins
- ansible
- CodeDeploy
- CodePipeline

Best practices for integrate early often, Modern deploy process,
- New branch for new functionality
- Create new functionality including tests for this new functionality
- Test code locally
- Rebase branch with changes on main branch
- Create PR
- Left Automation pipeline test/validate PR
- Left team review happends for authorize change
- Merge change to main branch

## Jenkins server
Pipelines are going to run on same jenkins server, using it as a slave so nodejs should be installed also on jenkins instance

Steps for jenkins role
- Create a jenkins role using "ansible-galaxy init jenkins" command on roles folder
- Role steps
  - Uninstall java 7, install java 8 (requirement from jenkins 2.54 and above)
  - Install jenkins yum repo and import GPG key
  - Install jenkins enabling repo (disabled by default)
  - Start jenkins at chkconfig level using service (if instance restart, jenkins is going to start again)

Steps for create Ansible playbook jenkins version
- Create new jenkins.yaml on Ansible Playbook root path indicating jenkins and nodejs as required roles to be executed. Not as a dependency for jenkins role because jenkins does not require nodejs for run, are independent softwares
- Create CF template using previous python troposphere script, call it jenkins-cf-template.py
- Install library for create an instance profile "pip install awacs"
- Change name and port of application: jenkins, 8080
- Add an instance IAM Profile (how instance interact with AWS Services, EC2 instance IAM permissions without needing to have to use access/secret keys)
- Add tropospher and iam sections on python troposphere script jenkins-cf-template.py
- Create new role, assign it to the Instance profile, assign Instance profile to EC2 instance
- Get CloudFormation template from Troposphere template
- Create instance 
- Get the Jenkins password 
- Once instance created, enter to the web on "http://IP:8080" and paste the password

```js
%> cat jenkins.yaml
---
- hosts: "{{ target | default('localhost') }}"
  become: yes
  roles:
    - jenkins
    - nodejs

%> cat jenkins-cf-template.py 
...
#New section
### Start
from troposphere.iam import (
    InstanceProfile,
    PolicyType as IAMPolicy,
    Role,
)
from awacs.aws import (
    Action,
    Allow,
    Policy,
    Principal,
    Statement,
)
from awacs.sts import AssumeRole
### Finish
...
#Role resource
#Create new role
### Start
t.add_resource(Role(
    "Role",
    AssumeRolePolicyDocument=Policy(
        Statement=[
            Statement(
                Effect=Allow,
                Action=[AssumeRole],
                Principal=Principal("Service", ["ec2.amazonaws.com"])
            )
        ]
    )
))
#Assign Role to Instance profile
t.add_resource(InstanceProfile(
    "InstanceProfile",
    Path="/",
    Roles=[Ref("Role")]
))
### Finish
...
#Assign Instance Profile to EC2 instance
t.add_resource(ec2.Instance(
    "instance",
    ImageId="ami-cfe4b2b0",
    InstanceType="t2.micro",
    SecurityGroups=[Ref("SecurityGroup")],
    KeyName=Ref("KeyPair"),
    UserData=ud,
    IamInstanceProfile=Ref("InstanceProfile"),
))

# jenkins-cf-template.py: Version with AMI instance type
# jenkins-cf-template-AMI2.py: Version with AMI2 instance type
# jenkins-cf-template-AMI2-R53.py: Version with AMI instance type and Route53 DNS record

%> python jenkins-cf-template.py > jenkins-cf3.yaml

%> aws cloudformation create-stack \
      --capabilities CAPABILITY_IAM \
      --stack-name jenkins \
      --template-body file://jenkins-cf4.yaml \
      --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS \
                   ParameterKey=HostedZone,ParameterValue=esausi.com

%> aws cloudformation wait stack-create-complete \
      --stack-name jenkins

%> aws cloudformation describe-stacks \
      --stack-name jenkins \
      --query 'Stacks[0].Outputs[0]'
{
    "OutputKey": "InstancePublicIp",
    "OutputValue": "54.164.157.91",
    "Description": "Public IP of our instance."
}

#If changes required on Troposphere script, generate yaml 2 and update stack
%> aws cloudformation update-stack \
      --capabilities CAPABILITY_IAM \
      --stack-name jenkins \
      --template-body file://jenkins-cf4.yaml \
      --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS \
                   ParameterKey=HostedZone,ParameterValue=esausi.com

%> aws cloudformation wait stack-update-complete \
      --stack-name jenkins

%> ssh -i ~/.ssh/EffectiveDevOpsAWS.pem ec2-user@54.164.157.91

ec2-user %> cat /var/log/jenkins/jenkins.log
...
*************************************************************

Jenkins initial setup is required. An admin user has been created and a password generated.
Please use the following password to proceed to installation:

a056b061da9041e79e02ea2a43121467

This may also be found at: /var/lib/jenkins/secrets/initialAdminPassword

*************************************************************
...

ec2-user %> cat /var/lib/jenkins/secrets/initialAdminPassword

%> aws cloudformation delete-stack \
      --stack-name jenkins 

%> aws cloudformation wait stack-delete-complete \
      --stack-name jenkins

```

## Backup Jenkins server with tar command
References: 
- https://devopscube.com/jenkins-backup-data-configurations/
- https://www.youtube.com/watch?v=grQ4cAcj81U
With this procedure is going to be full backup
- Plugins
- Configurations
- Pipelines
- Pipeline execution

Steps
- Enter to Jenkins server
- Sudo as root user
- Create a backup file using tar with gzip crompression
- Send file to a Backup storage

```js
%> sudo su -
%> mkdir /tmp/bkps
%> cd /tmp/bkps
%tmp/bkps> tar cvzf jenkins-backup-20210906-0646.gz /var/lib/jenkins/*

```

Other util commands,

- Extrac file content use

```js
%> tar xvfz jenkins-backup-20210906-0646.gz
```

- List the content

```js
%> tar tf jenkins-backup-20210906-0646.gz
```

## Backup Jenkins using "Periodic Backup Manager" plugin
Steps
- Create a new Jenkins installation
- Install "Periodic Backup Manager" plugin
- Create a dir "/tmp/bkps"
- Add permissions to user and group jenkins
- Download Backup from S3 bucket
- Configure Backup plugin "Periodic Backup Manager" 
- Create backup
  - 

```js
%> aws cloudformation create-stack \
      --capabilities CAPABILITY_IAM \
      --stack-name jenkinsbkp \
      --template-body file://jenkins-testbkp.yaml \
      --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS \
                   ParameterKey=HostedZone,ParameterValue=esausi.com

%> aws cloudformation wait stack-create-complete \
      --stack-name jenkinsbkp

%> aws cloudformation describe-stacks \
      --stack-name jenkinsbkp \
      --query 'Stacks[0].Outputs[0]'
```

- Unlock Jenkins
- Install "Periodic Backup Manager"
- Configure "Periodic Backup Manager"
Jenkins console -> Manage Jenkins -> Periodic Backup Manager -> Configure
  - Temporary directory: /tmp
  - Backup schedule (cron): H 10 * * *
  - Maximun backups in location: 3
  - Store no older than (days): 5
  - File Management Strategy: Full backup
  - Storage Strategy: TarGzStorare
  - Backup Location, LocalDirectory: /tmp/bkps
- Create backup: : Enter to the Jenkins console -> Manage Jenkins -> Periodic Backup Manager -> Backup



## Restore a Jenkins server from a /var/lib/jenkins backup
Permissions reference: https://aws.amazon.com/es/blogs/security/writing-iam-policies-how-to-grant-access-to-an-amazon-s3-bucket/

Steps
- Create EC2 instance with Jenkins dependencies and permissions to S3 backup bucket "esausi-backups"
- Unlock Jenkins
- Download backup file to EC2 instance
- Install "Periodic Backup Manager"
- Configure "Periodic Backup Manager"
Jenkins console -> Manage Jenkins -> Periodic Backup Manager -> Configure
  - Temporary directory: /tmp
  - Backup schedule (cron): H 10 * * *
  - Maximun backups in location: 3
  - Store no older than (days): 5
  - File Management Strategy: Full backup
  - Storage Strategy: TarGzStorare
  - Backup Location, LocalDirectory: /tmp/bkps
- Create backup: : Enter to the Jenkins console -> Manage Jenkins -> Periodic Backup Manager -> Backup

```js
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::esausi-backups"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::esausi-backups/*"
            ]
        }
    ]
}
```

Script for create EC2 instance with permissions: jenkins-testbkp.yaml