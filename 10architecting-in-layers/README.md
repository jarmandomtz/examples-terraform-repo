# Application in Layers

Reference,
- RDS public repo: https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/1.21.0

## Application architecture

This application has its components on separate layers,
- MySQL DB on RDS
- BackEnd frontend Java/Tomcat on 8080 (contained on jar file)
- Apache Web server 2.2 on 80

### Application version code
Original version
  source = "github.com/giuseppeborgese/effective_devops_with_aws__second_edition//terraform-modules//monolith-playground?ref=master"

  Creates 3 resources: EIP, SG, EC2

My Monolithic (**basic**) version:
  source = "github.com/esausi/effective_devops_with_aws__second_edition//terraform-modules//monolith-playground?ref=master"

  Creates 4 resources: EIP, SG, EC2, DNS record

My Scallable application version:
  source = "github.com/esausi/effective_devops_with_aws__second_edition//terraform-modules//monolith-playground?ref=develop"

  Creates 10 resources: EIP, SG-EC2, EC2-Instance, SG-DB, DB-Group, DB-Instance, Route53-DNS

## Deployment process

Use the example: 

Required parameters
  - var.my_ami_id
  - var.my_subnet
  - var.my_pem_keyname
  - var.my_vpc_id

Resources to be created,
- EIP
- SG
- EC2-Instance
- Route53 DNS Record: Using default values on variables.tf
- SG-DB
- DB-Group
- DB-Instance  


```js
%> cat main.tf
module "layered_application" {
  source = "github.com/esausi/effective_devops_with_aws__second_edition//terraform-modules//monolith-playground?ref=develop"
  my_vpc_id = "vpc-087ee567e804b3ff9" #"${var.my_default_vpc}"
  my_subnet = "pubnet-0b7bccf51cd0d15cf"
  my_ami_id = "ami-02e136e904f3da870"
  my_pem_keyname = "EffectiveDevOpsAWS"
}

%> terraform init -upgrade
%> terraform plan -out /tmp/tfill.out -target module.layered_application

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.layered_application.aws_eip.playground will be created
  + resource "aws_eip" "playground" {
 ...
  # module.layered_application.aws_instance.playground will be created
  + resource "aws_instance" "playground" {
  ...
  # module.layered_application.aws_route53_record.app will be created
  + resource "aws_route53_record" "app" {
  ...
  # module.layered_application.aws_security_group.playground will be created
  + resource "aws_security_group" "playground" {
  ...
  # module.layered_application.aws_security_group.rds will be created
  + resource "aws_security_group" "rds" {
 ...
  # module.layered_application.module.db.module.db_instance.aws_db_instance.this[0] will be created
  + resource "aws_db_instance" "this" {
  ...
  # module.layered_application.module.db.module.db_instance.random_id.snapshot_identifier[0] will be created
  + resource "random_id" "snapshot_identifier" {
  ...
  # module.layered_application.module.db.module.db_option_group.aws_db_option_group.this[0] will be created
  + resource "aws_db_option_group" "this" {
  ...
  # module.layered_application.module.db.module.db_parameter_group.aws_db_parameter_group.this[0] will be created
  + resource "aws_db_parameter_group" "this" {
 ...
  # module.layered_application.module.db.module.db_subnet_group.aws_db_subnet_group.this[0] will be created
  + resource "aws_db_subnet_group" "this" {
  ...
Plan: 10 to add, 0 to change, 0 to destroy.
...
Saved the plan to: /tmp/tfill.out
...

%> terraform apply /tmp/tfill.out
```
