provider "aws" { 
    access_key ="${var.aws_access_key}"
    secret_key ="${var.aws_secret_key}"
    region = "ap-southeast-1"
}

module "my-cdh-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-cdh-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-1a","ap-southeast-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  reuse_nat_ips        = false
  enable_vpn_gateway   = false
  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "my-cdh-bastion" {
  source                      = "github.com/terraform-community-modules/tf_aws_bastion_s3_keys"
  instance_type               = "t2.nano"
  ami                         = "ami-74fb8908"
  region                      = "ap-southeast-1"
  key_name                    = "mykey"
  iam_instance_profile        = "s3_readonly"
  s3_bucket_name              = "my-public-keys-bucket"
  vpc_id                      = "${module.my-cdh-vpc.vpc_id}"
  subnet_ids                  = "${module.my-cdh-vpc.public_subnets}"
  keys_update_frequency       = "*/15 * * * *"
  additional_user_data_script = "date"
  name  = "my-cdh-bastion"
  associate_public_ip_address = true
  ssh_user = "centos"
}

# allow ssh coming from bastion to boxes in vpc
#
resource "aws_security_group_rule" "allow_ssh" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  security_group_id = "${module.my-cdh-vpc.default_security_group_id}"
  source_security_group_id = "${module.my-cdh-bastion.security_group_id}" 
}


resource "aws_instance" "my-cdh-master" {
  ami           = "ami-74fb8908"
  instance_type = "t2.micro"
  subnet_id = "${module.my-cdh-vpc.public_subnets}"
  key_name = "amitthk_jenkinsmaster"
}
