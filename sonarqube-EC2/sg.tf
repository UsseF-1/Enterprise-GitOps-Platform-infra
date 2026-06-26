resource "aws_security_group" "sonarqube_sg" {
  name        = "sonarqube_sg"
  description = "sonarqube_sg-SG"

  tags = {
    Name = "sonarqube_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_from_myIP" {
  security_group_id = aws_security_group.sonarqube_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.sonarqube_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "sonarqube_port" {
  security_group_id = aws_security_group.sonarqube_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 9000
  ip_protocol       = "tcp"
  to_port           = 9000
}

resource "aws_vpc_security_group_egress_rule" "allowAllOutbound_ipv4" {
  security_group_id = aws_security_group.sonarqube_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allowAllOutbound_ipv6" {
  security_group_id = aws_security_group.sonarqube_sg.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}