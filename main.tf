resource "aws_autoscaling_group" "this" {
  desired_capacity     = 1
  max_size             = 1
  min_size             = 1
  name                 = var.stack_name
  vpc_zone_identifier  = [var.subnet_id]
  health_check_type    = "EC2"

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      propagate_at_launch = true
      value               = tag.value
    }
  }

}

resource "aws_launch_template" "this" {
  name                                 = var.stack_name
  image_id                             = var.ubuntu_ami_id == "" ? data.aws_ami.ubuntu[0].id : var.ubuntu_ami_id
  key_name                             = aws_key_pair.this.key_name
  ebs_optimized                        = true
  instance_type                        = var.instance_type
  instance_initiated_shutdown_behavior = "terminate"
  update_default_version               = true

  block_device_mappings {
    device_name = var.ubuntu_ami_id != "" ? "/dev/sda1" : data.aws_ami.ubuntu[0].root_device_name
    ebs {
      volume_size           = 8
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.this.id]
  }

  user_data = base64encode(templatefile("${path.module}/resources/templates/user_data.tpl", 
      {
        aws_region          = data.aws_region.current.name,
        eip_address         = aws_eip.this.public_ip,
        eip_allocation_id   = aws_eip.this.id,
        dns_name            = var.dns_name,
        server_address      = var.dns_name != "" ? var.dns_name : aws_eip.this.public_ip
        volume_path         = var.volume_path,
        volume_device_name  = "/dev/sdf"
        volume_id           = aws_ebs_volume.this.id
        docker_cidr         = var.docker_cidr
        docker_compose      = local.docker_compose
        create_client       = local.create_client
        revoke_client       = local.revoke_client
        routes              = [ for peered_network in var.peered_networks : "${element(split("/", peered_network), 0)} ${cidrnetmask(peered_network)}" ]
      }
  ))

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.tags
  }

  tag_specifications {
    resource_type = "network-interface"
    tags          = local.tags
  }

}

resource "aws_ebs_volume" "this" {
  availability_zone = data.aws_subnet.selected.availability_zone
  encrypted         = true
  type              = "gp2"
  size              = 30
  tags              = local.tags
}

resource "aws_key_pair" "this" {
  key_name    = var.stack_name
  public_key  = base64decode(aws_ssm_parameter.public_key.value)
  tags        = local.tags
}

resource "aws_eip" "this" {
  tags = local.tags
}

resource "aws_security_group" "this" {
  name        = var.stack_name
  description = "OpenVPN"
  vpc_id      = var.vpc_id
  tags        = local.tags

  ingress {
    description      = "OpenVPN"
    from_port        = 1194
    to_port          = 1194
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    self             = true
    cidr_blocks      = var.ssh_ingress_cidrs
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_ssm_parameter" "public_key" {
  name  = "${local.ssm_parameters_path}public-ssh-key"
  type  = "SecureString"
  value = base64encode(tls_private_key.this.public_key_openssh)
  tags  = local.tags
}

resource "aws_ssm_parameter" "private_key" {
  name  = "${local.ssm_parameters_path}private-ssh-key"
  type  = "SecureString"
  tier  = "Advanced"
  value = base64encode(tls_private_key.this.private_key_pem)
  tags  = local.tags
}  

resource "aws_iam_instance_profile" "this" {
  name = var.stack_name
  role = aws_iam_role.this.name
}

resource "aws_iam_role" "this" {
  name               = var.stack_name
  tags               = local.tags
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "this" {
  name   = var.stack_name
  role   = aws_iam_role.this.id
  policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AssociateAddress",
                "ec2:DisassociateAddress",
                "ec2:AttachVolume"
            ],
            "Resource": "*"
        }
    ]
}
  EOF
}



