# Store the Endpoint for Future reference
resource "local_file" "output_file" {
  depends_on = [aws_instance.jump_server]

  content = jsonencode({ details = [
    {
      "change_file_permission" : "chmod 400 '${local_file.jumpserver_key.filename}'",
      "ssh_login_with_pem" : "ssh -i '${local_file.jumpserver_key.filename}' -o StrictHostKeyChecking=no ec2-user@${aws_instance.jump_server.public_ip}",
      "ssh_login_ec2_user" : "ssh ec2-user@${aws_instance.jump_server.public_ip}",
      "https_url_test" : "http://${aws_instance.jump_server.public_ip}/index.html"
    },
    {
      "AWS_EC2" : aws_instance.jump_server
    }
  ] })
  filename = "${path.module}/specs.json"
}