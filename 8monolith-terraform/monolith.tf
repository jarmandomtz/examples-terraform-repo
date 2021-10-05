module "monolith_application" {
  source = "github.com/giuseppeborgese/effective_devops_with_aws__second_edition//terraform-modules//monolith-playground"
  my_vpc_id = "${var.my_default_vpc}"
  my_subnet = ""
  my_ami_id = ""
  my_pem_keyname = ""
}