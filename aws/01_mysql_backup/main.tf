provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

variable "ssh_key_path" {}
variable "vpc_id" {}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file(var.ssh_key_path)
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}
// 16kB tamaño maximo
data "template_file" "userdata" {
  template = file("${path.module}/userdata.sh")

}

resource "aws_iam_role" "ec2_restore_backup_role" {
  name = "ec2_restore_backup_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    tag-key = "restore-backup-role"
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_restore_profile"
  role = aws_iam_role.ec2_restore_backup_role.name
}

resource "aws_iam_role_policy" "s3_restore_backup_policy" {
  name = "s3_restore_backup_policy"
  role = "${aws_iam_role.ec2_restore_backup_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObjectAcl",
                "s3:GetObject",
                "ses:SendRawEmail",
                "s3:ListBucket",
                "s3:DeleteObject",
                "s3:GetBucketAcl",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::dmdomus30dias",
                "arn:aws:s3:::domusdatawarehouse",
                "arn:aws:s3:::dmdomus30dias/*",
                "arn:aws:s3:::domusdatawarehouse/*",
                "arn:aws:ses:us-west-2:415861705560:identity/domus.la"
            ]
        }       
    ]
}
EOF
}
resource "aws_instance" "web" {
  //ami           = data.aws_ami.ubuntu.id
  ami                  = "ami-0688ba7eeeeefe3cd"
  instance_type        = "t3.micro"
  key_name             = aws_key_pair.deployer.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id
  ]  
  user_data = data.template_file.userdata.rendered
  tags = {
    Name = "Backup mysql"
  }
  root_block_device {
    volume_size = 80
    volume_type = "gp3"
    encrypted   = true
  }

}

output "ip_instance" {
  value = aws_instance.web.public_ip
}

output "ssh" {
  value = "ssh -l ubuntu ${aws_instance.web.public_ip}"
}
