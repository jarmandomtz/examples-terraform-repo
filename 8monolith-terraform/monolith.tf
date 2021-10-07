provider "aws" {
  region = "us-east-2"
}

module "monolith_application" {
  #source = "github.com/giuseppeborgese/effective_devops_with_aws__second_edition//terraform-modules//monolith-playground"
  #source = "github.com/esausi/effective_devops_with_aws__second_edition//terraform-modules//monolith-playground?ref=develop"
  source = "github.com/esausi/effective_devops_with_aws__second_edition//terraform-modules//monolith-playground?ref=master"
  my_vpc_id = "vpc-087ee567e804b3ff9" #"${var.my_default_vpc}"
  my_subnet = "pubnet-0b7bccf51cd0d15cf"
  my_ami_id = "ami-02e136e904f3da870"
  my_pem_keyname = "EffectiveDevOpsAWS"
}