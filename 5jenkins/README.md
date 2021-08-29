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

%> python jenkins-cf-template.py > jenkins-cf3.yaml

%> aws cloudformation create-stack \
      --capabilities CAPABILITY_IAM \
      --stack-name jenkins \
      --template-body file://jenkins-cf3.yaml \
      --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS

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
      --template-body file://jenkins-cf3.yaml \
      --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS

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

```


