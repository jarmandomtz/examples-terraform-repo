# Monolithic application

Reference,
- https://github.com/giuseppeborgese/effective_devops_with_aws__second_edition
  module monolith-playground, detail [here](./monolith-app-detail.md)

## Application architecture

This application has this components on same EC2 instance,
- MySQL DB
- BackEnd frontend Java/Tomcat on 8080 (contained on jar file)
- Apache Web server 2.2 on 80

### Application versions
Original version
  source = "github.com/giuseppeborgese/effective_devops_with_aws__second_edition//terraform-modules//monolith-playground?ref=master"

  Creates 3 resources: EIP, SG, EC2

My Monolithic (**basic**) version:
  source = "github.com/esausi/effective_devops_with_aws__second_edition//terraform-modules//monolith-playground?ref=master"

  Creates 4 resources: EIP, SG, EC2, DNS record

My Scallable application version:
  source = "github.com/esausi/effective_devops_with_aws__second_edition//terraform-modules//monolith-playground?ref=develop"

  Creates 10 resources: EIP, SG-EC2, EC2, SG-DB, DBGroup, DB, 

  **PENDING TO COMPLETE LIST OR CERATED RESOURCES ON SCALLABLE APP**

## Deployment process

Use the example: monolith application

Required parameters
  - var.my_ami_id
  - var.my_subnet
  - var.my_pem_keyname
  - var.my_vpc_id

Resources to be created,
- EIP
- SG
- EC2
- Route53 DNS Record
  Using default values on variables.tf

variable "my_zone_id" {
  description = "the DNS zone Id"
  default = "Z0991180CEKYZJFHJA5I"
}

variable "my_zone_name" {
  description = "the DNS Zone Name"
  default = "app.esausi.com"
}


```js
%> cat monolith.tf
module "monolith_application" {
 #source = "github.com/giuseppeborgese/effective_devops_with_aws__second_edition//terraform-modules//monolith-playground"
  #source = "github.com/esausi/effective_devops_with_aws__second_edition//terraform-modules//monolith-playground?ref=develop"
  source = "github.com/esausi/effective_devops_with_aws__second_edition//terraform-modules//monolith-playground?ref=master"
  my_vpc_id = "vpc-087ee567e804b3ff9" #"${var.my_default_vpc}"
  my_subnet = "pubnet-0b7bccf51cd0d15cf"
  my_ami_id = "ami-02e136e904f3da870"
  my_pem_keyname = "EffectiveDevOpsAWS"
}

%> terraform init -upgrade
%> terraform plan -out /tmp/tfill.out -target module.monolith_application
%> terraform apply /tmp/tfill.out
```
