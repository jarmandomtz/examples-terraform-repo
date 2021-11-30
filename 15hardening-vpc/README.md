# Hardening

## VPC Hardening
Subnet types,
- Public
- Private
- Private with internet access

**Private subnet with internet access modes,**
- NAT Gateway
- Instance with NAT Gateway
- Internet Gateway

## Access to AWS resources from VPC on same region
- Using VPC Endpoints

VPC Endpoints creation, restrict Region, VPC, TableRoutes
Once created, subnets using this Table routes will be able to send traffict over this path/route

VPC Endpoints restriction on S3 buckets policy example:
Allows access to S3 bucket "my_secure_bucket" only using the VPC Endpoint "vpce-039f31bfec07367ea"

```js
{
    "Version": "2012-10-17",
    "Id": "Policy1415115909152",
     "Statement": [
        {
            "Sid": "Access-to-specific-VPCE-only",
            "Principal": "*",
            "Action": "s3:*",
            "Effect": "Deny",
            "Resource": ["arn:aws:s3:::my_secure_bucket",
                         "arn:aws:s3:::my_secure_bucket/*"],
            "Condition": {
                "StringNotEquals": {
     "aws:sourceVpce": "vpce-039f31bfec07367ea"
                 }
             }
        }
       ]
 }
```

### How to differeciate public subnet from private with internet access
- Public subnet on Route table has 0.0.0.0/0 adressed to Internet Gateway
- Private subnet with internet access has 0.0.0.0/0 adressed to Nat gateway on a Public subnet
A NAT Gateway is created on a Public subnet with an EIP which is internet reachable


## AWS WAF
Protecting Web Apps from Hacker attacks [here](./WAF.md)

## Access to EC2 on private subnet
- Jump on a bastion host in one public subnet
- Site to site VPN on AWS VPN service
- Place virtual VPN software in EC2 instance

## Network architecture and resource location
On a network with public and private subnets:

Resources located on public segment should be,
- ELBs
- Bastion hosts
- VPN (software) on EC2 instances
- NAT gateway (software) on EC2 instances

Resources locate on Private subnet with internet access,
- Internal ELBs
- EC2s behind ELB (internal or external) which require download or upload something to/from internet
- DBs which require download or upload something to/from internet

Resources locate on Private subnet without internet access,
- Resources which not required access to internet (EC2 instances, DBs)
- Resources which download update from internal repositories (EC2 instances, DBs)


