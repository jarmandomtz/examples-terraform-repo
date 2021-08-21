# Example using terraform + ansible

Create customized EC2 instance creation using Terraform Provisioner

Provisiones are primarily used as post build steps to install lightweight application or configuration management agents as Puppet agents or chef clients.
Provisiones uses *remote-exec* for stablish a connection with instance

*If there are changes on Terraform Provisioner secction after apply, it is not again executed, required to delete and apply again.*

Project structure
- helloworld-ec2.tf  Terraform file, using Terrafor Provisiones for setup instance
- terraform.tfvars   Variables and security information 
- .gitignore         For avoid upload security information to github repo
- terraform.tfstate  Automatically created, keeps infra creation state

## Test Instance creation

```js
%> terraform init
%> terraform validate
%> terraform plan -out t1.plan
%> terraform apply t1.plan
aws_instance.helloworld: Creating...
...
aws_instance.helloworld: Provisioning with 'remote-exec'...
...
aws_instance.helloworld (remote-exec): Connecting to remote host via SSH...
aws_instance.helloworld (remote-exec):   Host: 54.174.116.209
aws_instance.helloworld (remote-exec):   User: ec2-user
...
aws_instance.helloworld (remote-exec): Connected!
...
aws_instance.helloworld (remote-exec): Installing:
aws_instance.helloworld (remote-exec):  nodejs x86_64 0.10.48-3.el6 epel 2.1 M
..
aws_instance.helloworld (remote-exec): Complete!
aws_instance.helloworld (remote-exec): --2021-08-21 16:38:21--  https://raw.githubusercontent.com/yogeshraheja/Effective-DevOps-with-AWS/master/Chapter02/helloworld.js
...
aws_instance.helloworld (remote-exec): HTTP request sent, awaiting response...
aws_instance.helloworld (remote-exec): 200 OK
...
aws_instance.helloworld (remote-exec): helloworld start/running, process 2982
aws_instance.helloworld: Creation complete after 1m19s [id=i-0ccbf533ce1b15269]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

%> terraform show | grep -i public_ip
    associate_public_ip_address          = true
    public_ip                            = "35.171.18.132"

%> curl http://35.171.18.132:3000
Hello World, againt today 21/08/2021 ))

%> terraform destroy

```



