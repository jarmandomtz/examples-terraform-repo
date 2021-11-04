provider "aws" {
  region = "us-east-1"
}

module "flow-log-prerequisite" {
   #source = "github.com/giuseppeborgese/effective_devops_with_aws__second_edition//terraform-modules//vpc-flow-logs-prerequisite"
   source = "github.com/esausi/effective_devops_with_aws__second_edition//terraform-modules//vpc-flow-logs-prerequisite"
   prefix = "devops2nd"
 }

output "role" { 
    value = "${module.flow-log-prerequisite.rolename}" 
}

output "loggroup" { 
    value = "${module.flow-log-prerequisite.cloudwatch_log_group_arn}" 
}