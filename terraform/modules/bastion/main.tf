
# EC2
## 最新の AmazonLinux2 の AMI の ID を取得
data "aws_ssm_parameter" "this" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "this" {
  ami                  = data.aws_ssm_parameter.this.value
  instance_type        = "t2.nano"
  subnet_id            = var.subnet_id
  iam_instance_profile = aws_iam_instance_profile.this.name

  vpc_security_group_ids = [aws_security_group.this.id]

  lifecycle {
    ignore_changes = [
      instance_state,
      associate_public_ip_address
    ]
  }

  tags = {
    Name        = "${var.service_name}-bastion-${var.env}"
    Terraform   = "true"
    Environment = var.env
  }
}


# Security Group
## コンソール画面からしかアクセスしないので、 ingress は設定しない
resource "aws_security_group" "this" {
  name   = "${var.service_name}-bastion-sg-${var.env}"
  vpc_id = var.vpc_id

  ingress {
    description = "from rivate"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.service_name}-bastion-sg-${var.env}"
    Terraform   = "true"
    Environment = var.env
  }
}



# IAM 
## コンソールからセッションマネージャーでアクセスできるように、IAMロールとIAMポリシーを設定
resource "aws_iam_role" "this" {
  name = "${var.service_name}-${var.env}-bastion-iam-role"

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
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.service_name}-${var.env}-bastion-iam-instance-profile"
  role = aws_iam_role.this.name
}

data "aws_iam_policy" "this" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = data.aws_iam_policy.this.arn
}
