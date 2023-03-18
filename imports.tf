resource "null_resource" "change_file_permission" {
  depends_on = [
    aws_instance.jump_server
  ]
  provisioner "local-exec" {
    command = "chmod 400 '${local_file.jumpserver_key.filename}'"
  }
}

resource "null_resource" "uses_access_settings" {
  depends_on = [
    null_resource.change_file_permission
  ]

  triggers = {
    instance_id = aws_instance.jump_server.id
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo sed -i '/^PasswordAuthentication/s/no/yes/' /etc/ssh/sshd_config",
      "echo '${file("~/.ssh/id_rsa.pub")}' >> /home/ec2-user/.ssh/authorized_keys",
      "sudo systemctl restart sshd"
      # "ssh-keygen -o -t rsa -b 4096 -C \"sp-operator@simpragma.com\"",
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${local_file.jumpserver_key.filename}")
      host        = aws_instance.jump_server.public_ip
    }
  }
}

resource "null_resource" "web_server_setup" {
  depends_on = [
    null_resource.uses_access_settings
  ]

  triggers = {
    instance_id = aws_instance.jump_server.id
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${local_file.jumpserver_key.filename}")
    host        = aws_instance.jump_server.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
      "sudo chmod o+w /var/www/html/",
      "echo \"<h1>Deployed via Terraform remote exec</h1>\" | sudo tee /var/www/html/index.html"
    ]
  }
}

resource "null_resource" "file_transfer_htaccess" {
  depends_on = [
    null_resource.web_server_setup
  ]
  triggers = {
    instance_id = aws_instance.jump_server.id
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${local_file.jumpserver_key.filename}")
    host        = aws_instance.jump_server.public_ip
  }

  provisioner "file" {
    source      = "${path.module}/.htaccess"
    destination = "/var/www/html/.htaccess"
  }
}


