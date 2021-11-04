# VPC Hardening

Subnet types,
- Public
- Private
- Private with internet access

Private with internet access modes,
- NAT Gateway
- Instance with NAT Gateway
- Internet Gateway

Access to AWS resources from VPC on same region
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
