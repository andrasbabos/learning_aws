resource "aws_instance" "dvdstore" {
  ami                    = "ami-0cbfcdb45dcced1ca"
  instance_type          = "t3.medium"
  key_name               = "dvdstore_deployment"
  vpc_security_group_ids = [aws_security_group.dvdstore.id]

  tags = {
    project = "dvdstore"
  }
}