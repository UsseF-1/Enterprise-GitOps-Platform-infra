resource "aws_instance" "sonarqube" {

  ami                    = data.aws_ami.amiID.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.sonarqube_key.key_name
  vpc_security_group_ids = [aws_security_group.sonarqube_sg.id]

  tags = {
    Name    = "sonarqube-GitOps-platform"
    Project = "GitOps Platform"
  }

  provisioner "file" {
    source      = "sonar-setup.sh"
    destination = "/tmp/sonar-setup.sh"
  }

  connection {
    type        = "ssh"
    user        = var.webuser
    private_key = file("sonarqube-key-GitOps-platform")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/sonar-setup.sh",
      "sudo /tmp/sonar-setup.sh"
    ]
  }
}

resource "aws_ec2_instance_state" "sonarqube_state" {

  instance_id = aws_instance.sonarqube.id
  state       = "stopped"
}