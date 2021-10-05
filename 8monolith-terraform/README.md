# Monolithic application

Reference,
- https://github.com/giuseppeborgese/effective_devops_with_aws__second_edition
  module monolith-playground, detail [here](./monolith-app-detail.md)

## Application architecture

This application has this components,
- MySQL DB
- BackEnd frontend Java/Tomcat on 8080
- Apache Web server 2.2 on 80
- All contained on EC2 instance 

## Deployment process

Use the example: monolith application

Required parameters
  - var.my_ami_id
  - var.my_subnet
  - var.my_pem_keyname
  - var.my_vpc_id


```js
%> cat monolith.tf
PENDING TO COMPLETE FILE AND ADD HERE

%> terraform init -upgrade
%> terraform plan -out /tmp/tfill.out -target module.monolith_application
%> terraform apply /tmp/tfill.out
```
