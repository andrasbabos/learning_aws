resource "aws_instance" "dvdstore" {
  ami           = "ami-03d20f9dd906ec688"
  instance_type = "t3.micro"
  key_name = "dvdstore_deployment"
  vpc_security_group_ids = [aws_security_group.dvdstore.id]

  tags = {
    Name = "dvdstore"
  }
}