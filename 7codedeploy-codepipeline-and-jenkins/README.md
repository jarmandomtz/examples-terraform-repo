# CodeDeploy + CodePipeline + Jenkins
Now is time to integrate Codepipeline with Jenkins, for do this it is neccessary,
- Change IAM Instance role for integrate with CodePipeline
- Create/Update Jenkins instance for update the changes
  - If creating new instance, 
    - Download jenkins backup tar.gz file and extract to root jobs, secrets, credentials.xml and periodicbackup.xml 
    - Start jenkins console on navigator using: hppt://jenkins.esausi.com:8080/
    - Install secret key
    - Install default plugins
    - Restart Jenkins, "http://jenkins.esausi.com:8080/restart"
- Install CodePipeline plugin on Jenkins
- Create a Jenkins Job for the required processing
- Edit Pipeline for integrate a new CodePipeline stage

## Configuration

```js
%> cat jenkins-cf-template.py
...
t.add_resource(IAMPolicy(
    "Policy",
    PolicyName="AllowsCodePipeline",
    PolicyDocument=Policy(
        Statement=[
            Statement(
                Effect=Allow,
                Action=[Action("codepipeline", "*")],
                Resource=["*"]
            )
        ]
    ),
    Roles=[Ref("Role")]
))
...

%> python jenkins-cf-template.py > jenkins-cf.yaml

%> aws cloudformation create-stack \
      --capabilities CAPABILITY_IAM \
      --stack-name jenkins \
      --template-body file://jenkins-cf.yaml \
      --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS \
                   ParameterKey=HostedZone,ParameterValue=esausi.com

%> aws cloudformation wait stack-create-complete \
      --stack-name jenkins

%> aws cloudformation describe-stacks \
      --stack-name jenkins \
      --query 'Stacks[0].Outputs[0]'

%> aws cloudformation update-stack \
      --capabilities CAPABILITY_IAM \
      --stack-name jenkins \
      --template-body file://jenkins-cf.yaml \
      --parameters ParameterKey=KeyPair,ParameterValue=EffectiveDevOpsAWS \
                   ParameterKey=HostedZone,ParameterValue=esausi.com

%> aws cloudformation wait stack-update-complete \
      --stack-name jenkins    

%> aws cloudformation delete-stack \
      --stack-name jenkins 

%> aws cloudformation wait stack-delete-complete \
      --stack-name jenkins  
```

