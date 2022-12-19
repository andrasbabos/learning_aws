resource "aws_instance" "app_server" {
  ami           = "ami-03d20f9dd906ec688"
  instance_type = "t3.micro"

  #  tags = {
  #    Name = "ExampleAppServerInstance"
  #  }
}