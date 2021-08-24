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

ud = Base64(Join('\n', [
     "#!/bin/bash",
     "yum install --enablerepo=epel -y git",
     "yum install --enablerepo=epel -y ansible",
     AnsiblePullCmd,
     "{} > /tmp/ansible-pull-crontab-cmd".format(AnsiblePullCmd),
     "sudo crontab -u ec2-user /tmp/ansible-pull-crontab-cmd"
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
    )
))

t.add_resource(InstanceProfile(
    "InstanceProfile",
    Path="/",
    Roles=[Ref("Role")]
))
### Finish

t.add_resource(ec2.Instance(
    "instance",
    ImageId="ami-cfe4b2b0",
    InstanceType="t2.micro",
    SecurityGroups=[Ref("SecurityGroup")],
    KeyName=Ref("KeyPair"),
    UserData=ud,
    IamInstanceProfile=Ref("InstanceProfile"),
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
        "http://", GetAtt("instance", "PublicDnsName"),
        ":", ApplicationPort
    ]),
))

#print t.to_json()
print(t.to_json())
