# Example using terraform + ansible

This example just creates an instance using existing SG on defaul VPC

Project structure
- ec2.tf             Terraform HCL file using AWS provider for create an EC2 instance
- terraform.tfvars   Variables and security information 
- .gitignore         For avoid upload security information to github repo
- terraform.tfstate  Automatically created, keeps infra creation state

## Test Instance creation

```js
%> cat ec2.tf

# Provider Configuration for AWS
provider "aws" {
  region     = "us-east-1"
}

# Resource Configuration for AWS
resource "aws_instance" "myserver" {
  ami = "ami-cfe4b2b0"
  instance_type = "t2.micro"
  key_name = "EffectiveDevOpsAWS"
  vpc_security_group_ids = ["sg-5b584a7f"]

  tags = {
    Name = "helloworld"
  }
}

%> terraform init
%> terraform validate
%> terraform plan -out t1.plan
%> terraform apply t1.plan
%> terraform show
# aws_instance.myserver:
resource "aws_instance" "myserver" {
    ami                                  = "ami-cfe4b2b0"
 ...
    private_dns                          = "ip-172-31-86-118.ec2.internal"
    private_ip                           = "172.31.86.118"
    public_dns                           = "ec2-3-87-8-61.compute-1.amazonaws.com"
    public_ip                            = "3.87.8.61"
 ...
}

%> terraform destroy
aws_instance.myserver: Refreshing state... [id=i-054a47413bcb834e1]
...

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

aws_instance.myserver: Destroying... [id=i-054a47413bcb834e1]
aws_instance.myserver: Still destroying... [id=i-054a47413bcb834e1, 10s elapsed]
aws_instance.myserver: Still destroying... [id=i-054a47413bcb834e1, 20s elapsed]
aws_instance.myserver: Still destroying... [id=i-054a47413bcb834e1, 30s elapsed]
aws_instance.myserver: Still destroying... [id=i-054a47413bcb834e1, 40s elapsed]
aws_instance.myserver: Destruction complete after 41s

Destroy complete! Resources: 1 destroyed.
```



