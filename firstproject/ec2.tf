# Provider Configuration for AWS
provider "aws" {
  #source = "./terraform.tfvars"
  #access_key = var.aws_access_key
  #secret_key = var.aws_secret_key
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
