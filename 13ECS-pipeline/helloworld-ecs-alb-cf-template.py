"""Generating CloudFormation template."""

from troposphere import elasticloadbalancingv2 as elb

from troposphere import (
    Export,
    GetAtt,
    ImportValue,
    Join,
    Output,
    Ref,
    Select,
    Split,
    Sub,
    Template,
    ec2,
    Parameter
)

from troposphere.route53 import RecordSetType

t = Template()

t.set_description("Effective DevOps in AWS: ALB for the ECS Cluster")

t.add_resource(ec2.SecurityGroup(
    "LoadBalancerSecurityGroup",
    GroupDescription="Web load balancer security group.",
    VpcId=ImportValue(
        Join(
            "-",
            [Select(0, Split("-", Ref("AWS::StackName"))),
                "cluster-vpc-id"]
        )
    ),
    SecurityGroupIngress=[
        ec2.SecurityGroupRule(
            IpProtocol="tcp",
            FromPort="3000",
            ToPort="3000",
            CidrIp="0.0.0.0/0",
        ),
    ],
))

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

t.add_resource(elb.Listener(
    "Listener",
    Port="3000",
    Protocol="HTTP",
    LoadBalancerArn=Ref("LoadBalancer"),
    DefaultActions=[elb.Action(
        Type="forward",
        TargetGroupArn=Ref("TargetGroup")
    )]
))

hostedzone = t.add_parameter(
    Parameter(
        "HostedZone",
        Description="The DNS name of an existing Amazon Route 53 hosted zone",
        Type="String",
    )
)

dnsPrefix = t.add_parameter(
    Parameter(
        "DnsPrefix",
        Description="The DNS prefix name for the Load Balancer DNS name",
        Type="String",
    )
)

myDNSRecord = t.add_resource(
    RecordSetType(
        "myDNSRecord",
        HostedZoneName=Join("", [Ref(hostedzone), "."]),
        Comment="DNS name for my loadbalancer.",
        Name=Join(
            "", [Ref(dnsPrefix), ".", Ref(hostedzone), "."]
        ),
        Type="CNAME",
        TTL="900",
        ResourceRecords=[GetAtt("LoadBalancer", "DNSName")],
    )
)

t.add_output(Output(
    "TargetGroup",
    Description="TargetGroup",
    Value=Ref("TargetGroup"),
    Export=Export(Sub("${AWS::StackName}-target-group")),
))

t.add_output(Output(
    "URL",
    Description="Helloworld URL",
    Value=Join("", ["http://", GetAtt("LoadBalancer", "DNSName"), ":3000"])
))

t.add_output(Output(
    "URLRoute53",
    Description="Helloworld URL using DNS Zone",
    Value=Join("", ["http://", Ref(myDNSRecord), ":3000"])
))

print(t.to_yaml())