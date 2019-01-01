

provider "aws" { 
    access_key ="${var.aws_access_key}"
    secret_key ="${var.aws_secret_key}"
    region = "ap-southeast-1"
}

resource "aws_instance" "tomcatserver" {
    ami = "ami-6f198a0c"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"

  tags {
      Name = "tomcatserver"
      Description = "Used to deploy wars to tomcat"
  }

  provisioner "local-exec" {
    command = "echo ${aws_instance.tomcatserver.private_ip} >> file.txt"
  }

}