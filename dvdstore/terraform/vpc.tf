resource "aws_security_group" "dvdstore" {
  name        = "dvdstore"
  description = "dvdstore basic rules"
  tags = {
    Name = "dvdstore"
  }
}

resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.dvdstore.id
}

resource "aws_security_group_rule" "ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.dvdstore.id
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.dvdstore.id
}

resource "aws_security_group_rule" "allow_all_in_sg" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  self              = true
  security_group_id = aws_security_group.dvdstore.id
}