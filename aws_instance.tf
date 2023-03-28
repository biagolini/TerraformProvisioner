resource "aws_instance" "public_instance" {
  ami             = data.aws_ami.amazon_linux.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.webdmz_sg.id]
  key_name        = local.keyName
  tags = {
    Name = "My public instance"
  }
  user_data = <<EOF
              #!/bin/bash
              yum update -y
              yum install httpd -y
              service httpd start
              chkconfig httpd on
              cd /var/www/html
              echo "<html><body><div style='align-items: center'><h1 style='width: 100%; text-align: center'> ID: $(curl http://169.254.169.254/latest/meta-data/instance-id)</h1><h1 style='width: 100%; text-align: center'>IP: $(curl http://169.254.169.254/latest/meta-data/public-ipv4)</h1></html>" > index.html
              EOF

  provisioner "local-exec" {
    command = "echo  'See my var:\nlocal-exec var1:' $FOO  '\nlocal-exec var2:' $BAR  '\nTerraform local: ' ${local.loremIpsum}"
    environment = {
      FOO = "Hello, World!"
      BAR = timestamp()
    }
  }

  # connection {
  #   type        = "ssh"
  #   user        = "root"
  #   private_key = file(local.privateKeyPath)
  #   host        = aws_instance.public_instance.public_ip
  # }

  # provisioner "file" {              # The file provisioner can be used to copy files or directories from the local machine to the remote machine
  #   source      = "conf/myapp.conf" # path to local file
  #   destination = "/etc/myapp.conf" # path to remote machine
  # }


  # provisioner "remote-exec" {
  #   inline = [
  #     "#!/bin/bash",
  #     "cd /var/www/html",
  #     "echo '<html><body><div><h1>NEW HTML CODE</h1></html>' > index.html"
  #   ]
  # }

  timeouts {
    create = "2m"
    delete = "2m"
  }

}
