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
      "sudo yum install --enablerepo=epel -y ansible git",
      "sudo /usr/bin/ansible-pull -U https://github.com/jarmandomtz/ansible-pull-gitrepo -C develop helloworld.yml -i localhost -u jarmandomtz -v --sleep 60 >> /tmp/ansible-pull.log",
      "sudo echo '*/2 * * * * /usr/bin/ansible-pull -U https://github.com/jarmandomtz/ansible-pull-gitrepo -C develop helloworld.yml -i localhost -u jarmandomtz -v --sleep 60 >> /tmp/ansible-pull.log' > /tmp/ansible-pull-crontab-cmd", 
      "sudo crontab -u ec2-user /tmp/ansible-pull-crontab-cmd",
    ]
  }
}

output "myserver" {
  value = "${aws_instance.myserver.public_ip}"
}
