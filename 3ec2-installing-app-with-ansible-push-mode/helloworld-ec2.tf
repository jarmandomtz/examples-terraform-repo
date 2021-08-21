#AWS authentication
provider "aws" {
# Using credentials on ~/.aws/credentials
  profile = "terraform.aws.admin"
  region = "us-east-1" # Virginia
}

#Resource configuration for AWS
resource "aws_instance" "myserver" {
  ami = "ami-cfe4b2b0"
  instance_type = "t2.micro"
  key_name = "EffectiveDevOpsAWS"
  vpc_security_group_ids = [
    "sg-0f3a12467d76a54a2"
  ]
  tags = {
    Name = "helloworld"
  }

#Connect to created instance and execute remote commands
  provisioner "remote-exec" {
    connection {
      user = "ec2-user"
      private_key = file("~/.ssh/EffectiveDevOpsAWS.pem")
      host = self.public_ip
    }
    inline = [
      "echo 'Logging from EC2 instance'",
    ]
  }

  provisioner "local-exec" {
    command = "echo '${self.public_ip}' > ./myinventory"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i myinventory --private-key ~/.ssh/EffectiveDevOpsAWS.pem helloworld.yml"
  }
}

output "myserver" {
  value = "${aws_instance.myserver.public_ip}"
}
