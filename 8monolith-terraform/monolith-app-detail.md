# Monolithic application

Reference,
- https://github.com/giuseppeborgese/effective_devops_with_aws__second_edition

## Architecture

This application has this components,
- MySQL DB
- BackEnd frontend Java/Tomcat on 8080
- Apache Web server 2.2 on 80
- All contained on EC2 instance 

## Repo structure

Is a series of Terraform modules,
./terraform-modules
|_ ddos_protection
|_ limit-the-admin area
|_ monolith-playground
|_ vpc-flow-logs-prerequisite
|_ webapp-playground

## Monolith application module

The module we are going to use is: monolith-playground

Structure
|_ demo-0.0.1-SNAPSHOT.jar
|_ tomcat.service
|_ tomca.sh
|_ main.tf
|_ variables.tf
|_ outputs.tf

Detail: main.tf
- Receives parameters (defined on variables.tf):
  - var.my_ami_id
  - var.my_subnet
  - var.my_pem_keyname
  - var.my_vpc_id
- Create resources
  - aws_instance "playground"
  - aws_security_group "playground", ingress 0.0.0.0/0:80,22. egress 0.0.0.0/0
  - aws_eip "playground"
- On UserData section
  - Install required software
  - Locate tomcat files, assign permissions
  - Configure Apache Web server
  - Create DB, table, user, assign permissions
  - Copy application files to the instance (binary app, service definition, shell script for start)
  - Start tomcat service
