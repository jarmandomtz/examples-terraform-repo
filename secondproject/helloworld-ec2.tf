#AWS authentication
provider "aws" {
# access_key = ""
# secret_key = ""
# profile = "terraform.aws.admin"
# region = "us-west-2" # Ohio
  region = "us-east-1" # Virginia
}

#Resource configuration for AWS
resource "aws_instance" "helloworld" {
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
      "sudo yum install --enablerepo=epel -y nodejs",
      #"sudo wget https://raw.githubusercontent.com/yogeshraheja/Effective-DevOps-with-AWS/master/Chapter02/helloworld.js -O /home/ec2-user/helloworld.js",
      "sudo wget https://raw.githubusercontent.com/jarmandomtz/ansible-pull-gitrepo/develop/roles/helloworld/files/helloworld.js -O /home/ec2-user/helloworld.js",
      #"sudo wget https://raw.githubusercontent.com/yogeshraheja/Effective-DevOps-with-AWS/master/Chapter02/helloworld.conf -O /etc/init/helloworld.conf",
      "sudo wget https://raw.githubusercontent.com/jarmandomtz/ansible-pull-gitrepo/develop/roles/helloworld/files/helloworld.conf -O /etc/init/helloworld.conf",
      "sudo start helloworld",
    ]
  }
}
