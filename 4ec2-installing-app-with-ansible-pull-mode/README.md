# EC2 using Terraform and Ansible in pull mode

Actions executed by technology

Terraform
- Creation of EC2 instance
- Installation of git and ansible
- Execution of ansible-pull command on EC2 instance
- Creation of crontab job for run cyclicly ansible-pull (creation of file and load of job to crontab)

Ansible
- Execution of helloworld.yml playbook, composed by next roles
  - helloworld: install app, depends of nodejs
  - nodejs:     installs nodejs, npm and npm packages

Security group used needs to have 22 port open for enable ansible ssh connection

Using ~/.aws/credentials file
If not created, create using "aws configure"

Project structure,
- helloworld-ec2.tf  Terraform file, using Terrafor Provisiones for setup instance
- .gitignore         For avoid upload security information to github repo
- gitrepo/ansible-pull-gitrepo
                     Ansible playbook with roles for install app and dependencies

```js
%> terraform init
%> terraform validate
%> terraform plan -out t1.plan
%> terraform apply t1.plan
aws_instance.myserver: Creating...
...
aws_instance.myserver (remote-exec): Connecting to remote host via SSH...
aws_instance.myserver (remote-exec):   Host: 34.204.82.109
...
aws_instance.myserver (remote-exec): Connected!
...
aws_instance.myserver (remote-exec): Resolving Dependencies
aws_instance.myserver (remote-exec): --> Running transaction check
aws_instance.myserver (remote-exec): ---> Package ansible.noarch 0:2.6.20-1.el6 will be installed
...
aws_instance.myserver (remote-exec): ---> Package git.x86_64 0:2.18.5-2.73.amzn1 will be installed
...
aws_instance.myserver (remote-exec): Installed:
aws_instance.myserver (remote-exec):   ansible.noarch 0:2.6.20-1.el6
aws_instance.myserver (remote-exec):   git.x86_64 0:2.18.5-2.73.amzn1
...
aws_instance.myserver (remote-exec): Complete!
...
aws_instance.myserver: Creation complete after 2m31s [id=i-0c8459da6c0e5e1c0]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

myserver = "34.204.82.109"

%> curl http://34.204.82.109:3000
Hello World, 2021/08/21 20:02:35

%> terraform destroy
```

## Validating crontab on EC2 instance

```js
armando@ubuntu:~/prg/terraform/examples-terraform-repo/4ec2-installing-app-with-ansible-pull-mode$ ssh -i ~/.ssh/EffectiveDevOpsAWS.pem ec2-user@34.204.82.109

ec2-user@ip-172-31-62-244 ~]$ crontab -l
*/2 * * * * /usr/bin/ansible-pull -U https://github.com/jarmandomtz/ansible-pull-gitrepo -C develop helloworld.yml -i localhost -u jarmandomtz -v --sleep 60 >> /tmp/ansible-pull.log

[ec2-user@ip-172-31-62-244 ~]$ cat /tmp/ansible-pull.log | grep "Starting Ansible Pull"
Starting Ansible Pull at 2021-08-21 21:03:44
Starting Ansible Pull at 2021-08-21 21:06:01
Starting Ansible Pull at 2021-08-21 21:08:02
```