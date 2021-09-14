# Using CodeDeploy and CodePipeline

## Setup
In order to use CodeDeploy, EC2 instance require to use CodeDeploy Agent, an executable from S3.
This could be done using a custom Ansible library, which should be on /usr/share/my_modules or root of our ansible repo

Steps,
- On root create "library" dir
- Download binary
- Edit ansible.cfg and specify the location of the library
- Create a codedeploy role
- Copy Troposphere template and customize
- Generate CloudFormation script

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

%> aws cloudformation create-stack \
      --capabilities CAPABILITY_IAM \
      --stack-name helloworld-staging \
      --template-body file://nodeserver-cf.yaml \
      --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS \
                   ParameterKey=HostedZone,ParameterValue=esausi.com \
                   ParameterKey=InstanceDNSRecordName,ParameterValue=nodeserver
```


