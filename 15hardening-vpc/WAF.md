# WAF

## Prerequisites
Resources required,
- EC2 instance
- EC2 SG
- ALB
- ALB Listener
- ALB Target group
- ALB SG
- ALB Target group attachment (link between ALB and EC2)

```js
%> cat main.tf
module "webapp-playground" {
  source = "github.com/esausi/effective_devops_with_aws__second_edition//terraform-modules//webapp-playground"
  subnet_public_A = "subnet-0b7bccf51cd0d15cf"
  subnet_public_B = "subnet-08a2778b52bc1318c"
  subnet_private = "subnet-090f5f67b021cd5d3"
  vpc_id = "vpc-087ee567e804b3ff9"
  my_ami = "ami-b70554c8"
  pem_key_name = "EffectiveDevOpsAWS"
}

%> terraform init -upgrade

%> terraform plan -out plan.out

%> terraform apply plan.out
```
