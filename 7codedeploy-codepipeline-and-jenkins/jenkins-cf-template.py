"""Generating CloudFormation template."""
#Because SecurityGroup is not restrictec for our specific IP, this is not needed
#from ipaddress import ip_network
#from ipify import get_ip

#Reference: https://www.ipify.org/
from requests import get

from troposphere import (
    Base64,
    ec2,
    GetAtt,
    Join,
    Output,
    Parameter,
    Ref,
    Template,
)

#Libs added for specify an IAM role to the instance, IAM permissions directly to EC2 instances without having to use access keys and secrets access keys
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
from troposphere.route53 import RecordSetType
### Finish

ApplicationName = "jenkins"
ApplicationPort = "8080"
PublicCidrIp = get('https://api.ipify.org').text + "/0" #str(ip_network(get_ip()))

GithubAccount = "jarmandomtz"
GithubAnsibleURL = "https://github.com/{}/ansible-pull-gitrepo".format(GithubAccount)
GithubBranch = "develop"

AnsiblePullCmd = "/usr/bin/ansible-pull -U {} {}.yml -C {} -i localhost -v --sleep 60 >> /tmp/ansible-pull.log".format(GithubAnsibleURL,ApplicationName, GithubBranch)

t = Template()

#t.add_description("Effective DevOps in AWS: HelloWorld web application")
t.set_description("Effective DevOps in AWS: HelloWorld web application")

t.add_parameter(Parameter(
    "KeyPair",
    Description="Name of an existing EC2 KeyPair to SSH",
    Type="AWS::EC2::KeyPair::KeyName",
    ConstraintDescription="must be the name of an existing EC2 KeyPair.",
))

t.add_resource(ec2.SecurityGroup(
    "SecurityGroup",
    GroupDescription="Allow SSH and TCP/{} access".format(ApplicationPort),
    SecurityGroupIngress=[
        ec2.SecurityGroupRule(
            IpProtocol="tcp",
            FromPort="22",
            ToPort="22",
#            CidrIp=PublicCidrIp,
            CidrIp="0.0.0.0/0",
        ),
        ec2.SecurityGroupRule(
            IpProtocol="tcp",
            FromPort=ApplicationPort,
            ToPort=ApplicationPort,
            CidrIp="0.0.0.0/0",
        ),
    ],
))

# ud = Base64(Join('\n', [
#     "#!/bin/bash",
#     "sudo yum install --enablerepo=epel -y nodejs",
#     "wget http://bit.ly/2vESNuc -O /home/ec2-user/helloworld.js",
#     "wget http://bit.ly/2vVvT18 -O /etc/init/helloworld.conf",
#     "start helloworld"
# ]))

#  "sudo echo '*/2 * * * * /usr/bin/ansible-pull -U https://github.com/jarmandomtz/ansible-pull-gitrepo -C develop helloworld.yml -i localhost -u jarmandomtz -v --sleep 60 >> /tmp/ansible-pull.log' > /tmp/ansible-pull-crontab-cmd", 
#  "sudo crontab -u ec2-user /tmp/ansible-pull-crontab-cmd",

#Installation of ansible not working on AMI2
#"yum install -y ansible",
#"sudo amazon-linux-extras install ansible2 -y",

ud = Base64(Join('\n', [
     "#!/bin/bash",
     "sudo systemctl enable amazon-ssm-agent",
     "sudo systemctl start amazon-ssm-agent",
     "yum install -y git",
     "sudo amazon-linux-extras install -y ansible2",
     AnsiblePullCmd,
     "echo '*/2 * * * * {}' > /tmp/ansible-pull-crontab-cmd".format(AnsiblePullCmd),
     "sudo crontab -u ec2-user /tmp/ansible-pull-crontab-cmd",
     "sudo mkdir -p /tmp/bkps",
     "sudo aws s3 cp s3://esausi-backups/jenkins/backup_2021_09_12_20_01_18_245.pbobj /tmp/bkps/",
     "sudo aws s3 cp s3://esausi-backups/jenkins/backup_2021_09_12_20_01_18_245.tar.gz /tmp/bkps/",
     "sudo chown -R jenkins /tmp/bkps",
     "sudo chgrp -R jenkins /tmp/bkps"
]))

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
    ),
    Description='Role for add SSM capabilities to Jenkins instance',
    ManagedPolicyArns=[
        'arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy',
        'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore'
    ]
))

t.add_resource(InstanceProfile(
    "InstanceProfile",
    Path="/",
    Roles=[Ref("Role")]
))
### Finish

#Add S3 Bucket permissions
t.add_resource(IAMPolicy(
    "S3Policy",
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
    Roles=[Ref("Role")]
))

#Add CodePipeline service permissions
t.add_resource(IAMPolicy(
    "CodepipelinePolicy",
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

#ami-cfe4b2b0:          Linux AMI 
#ami-06cf15d6d096df5d2  Linux AMI 2 ARM
#ami-0c2b8ca1dad447f8a  Linux AMI 2 x86 - t2.micro
instance = t.add_resource(ec2.Instance(
    "instance",
    ImageId="ami-0c2b8ca1dad447f8a",
    InstanceType="t2.micro",
    SecurityGroups=[Ref("SecurityGroup")],
    KeyName=Ref("KeyPair"),
    UserData=ud,
    IamInstanceProfile=Ref("InstanceProfile"),
))

hostedzone = t.add_parameter(
    Parameter(
        "HostedZone",
        Description="The DNS name of an existing Amazon Route 53 hosted zone",
        Type="String",
    )
)

myDNSRecord = t.add_resource(
    RecordSetType(
        "myDNSRecord",
        HostedZoneName=Join("", [Ref(hostedzone), "."]),
        Comment="DNS name for my instance.",
        Name=Join(
            "", [Ref(instance), ".", Ref("AWS::Region"), ".", Ref(hostedzone), "."]
        ),
        Type="A",
        TTL="900",
        ResourceRecords=[GetAtt("instance", "PublicIp")],
    )
)

myJenkinsDNSRecord = t.add_resource(
    RecordSetType(
        "myJenkinsDNSRecord",
        HostedZoneName=Join("", [Ref(hostedzone), "."]),
        Comment="DNS name for my instance.",
        Name=Join(
            "", ["jenkins", ".", Ref(hostedzone), "."]
        ),
        Type="A",
        TTL="900",
        ResourceRecords=[GetAtt("instance", "PublicIp")],
    )
)

t.add_output(Output(
    "DomainName", 
    Description="DNS using instance ID", 
    Value=Ref(myDNSRecord)
))

t.add_output(Output(
    "InstancePublicIp",
    Description="Public IP of our instance.",
    Value=GetAtt("instance", "PublicIp"),
))

t.add_output(Output(
    "WebUrl",
    Description="Application endpoint",
    Value=Join("", [
#        "http://", GetAtt("instance", "PublicDnsName"),
        "http://", Ref("myJenkinsDNSRecord"),
        ":", ApplicationPort
    ]),
))

#print t.to_json()
#print(t.to_json())
print(t.to_yaml())