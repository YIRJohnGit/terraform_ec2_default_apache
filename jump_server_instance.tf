resource "aws_instance" "jump_server" {
  ami             = "ami-0cca134ec43cf708f"
  instance_type   = var.jump_server_instance_types
  key_name        = "${var.short_project_name}-key-jumpserver"
  security_groups = [aws_security_group.jumpserver.name]
  user_data       = file("jump_server_autoexec.sh")

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${local_file.jumpserver_key.filename}")
    host        = self.public_ip # data.aws_eip.existing_eip.public_ip # self.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y"
    ]
  }
  tags = {
    Name = "${var.short_project_name}-jumpserver"
  }
  depends_on = [
    aws_key_pair.key_jumpserver
  ]
}

# Key Pair Setting
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_jumpserver" {
  key_name   = "${var.short_project_name}-key-jumpserver"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "jumpserver_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "${var.short_project_name}-key-jumpserver.pem"
}

# Security Group
resource "aws_security_group" "jumpserver" {
  name        = "${var.short_project_name}-ec2-jumpserver-sg"
  description = "${var.short_project_name} - Security Group for EC2 Instance"

  ingress {
    description      = "${var.short_project_name} - Allow TLS from VPC http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "${var.short_project_name} - Allow TLS from VPC https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "${var.short_project_name} - Allow TLS from VPC SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "${var.short_project_name} - Allow all outbound traffics"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.short_project_name}-jumpserver-sg"
  }
}
