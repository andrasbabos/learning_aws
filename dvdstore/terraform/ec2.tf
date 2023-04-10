resource "aws_instance" "dvdstore" {
  ami                    = "ami-0f960c8194f5d8df5"
  instance_type          = "t3.micro"
  key_name               = "dvdstore_deployment"
  vpc_security_group_ids = [aws_security_group.dvdstore.id]

  tags = {
    project = "dvdstore"
  }
}