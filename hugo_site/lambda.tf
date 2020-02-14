# Create template for lambda source
# Create template for rebuild script
# Create ZIP of lambda source
# Create access policy for lambda
# Create role for lambda
# Create log group for lambda
# Create lambda

data "archive_file" "lambda" {
  type        = "zip"
  output_path = "/tmp/lambda.zip"

  source {
    content  = data.template_file.lambda.rendered
    filename = "index.js"
  }
}

data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:AssociateIamInstanceProfile",
    ]

    resources = [
      "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateTags",
    ]

    resources = [
      "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:volume/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:RunInstances",
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:InstanceType"

      values = [
        var.instance_type,
      ]
    }

    resources = [
      "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:RunInstances",
    ]

    resources = [
      "arn:aws:ec2:${var.region}::image/${var.ami}",
      "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
      "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:security-group/${aws_security_group.ec2.id}",
      "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:subnet/*",
      "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:volume/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      aws_iam_role.ec2.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.lambda.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
    ]

    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${replace("/${var.github_secret_parameter_name}", "////", "/")}",
    ]
  }
}

data "template_file" "lambda" {
  template = file("${path.module}/templates/node/index.js")

  vars = {
    ami                          = var.ami
    github_secret_parameter_name = var.github_secret_parameter_name
    instance_type                = var.instance_type
    site_name                    = var.site_name
    user_data                    = base64encode(data.template_file.rebuild.rendered)
  }
}

data "template_file" "postprocess" {
  template = file(var.postprocess_template)

  vars = {
    git_repo  = var.git_repo
    repo_dir  = "/tmp/site_repo"
    site_name = var.site_name
  }
}

data "template_file" "preprocess" {
  template = file(var.preprocess_template)

  vars = {
    git_repo  = var.git_repo
    repo_dir  = "/tmp/site_repo"
    site_name = var.site_name
  }
}

data "template_file" "rebuild" {
  template = file("${path.module}/templates/shell/rebuild.sh")

  vars = {
    git_repo     = var.git_repo
    hugo_version = var.hugo_version
    postprocess  = data.template_file.postprocess.rendered
    preprocess   = data.template_file.preprocess.rendered
    repo_dir     = "/tmp/site_repo"
    site_name    = var.site_name
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${replace(var.site_name, ".", "_")}-rebuild"
  retention_in_days = 3

  tags = {
    (var.tag_name) = var.site_name
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.site_name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.site_name}-lambda"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_lambda_function" "rebuild" {
  filename      = "/tmp/lambda.zip"
  function_name = "${replace(var.site_name, ".", "_")}-rebuild"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  memory_size   = 128
  runtime       = "nodejs6.10"
  timeout       = 10

  tags = {
    (var.tag_name) = var.site_name
  }

  depends_on = [data.archive_file.lambda]
}

