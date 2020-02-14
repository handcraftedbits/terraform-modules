# Create access policy for EC2 instance
# Create role for EC2 instance
# Create security group that disallows access to the EC2 instance

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "ec2" {
  statement {
    effect = "Allow"

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.root.arn,
      "${aws_s3_bucket.root.arn}/*",
    ]
  }
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.site_name}-ec2"
  role = aws_iam_role.ec2.id
}

resource "aws_iam_role" "ec2" {
  name               = "${var.site_name}-ec2"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy" "ec2" {
  name   = "${var.site_name}-ec2"
  role   = aws_iam_role.ec2.id
  policy = data.aws_iam_policy_document.ec2.json
}

resource "aws_security_group" "ec2" {
  name = "${var.site_name}-disallow-all"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    var.tag_name = var.site_name
  }
}

