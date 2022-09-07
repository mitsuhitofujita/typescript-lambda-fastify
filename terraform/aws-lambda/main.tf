terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.27.0"
    }
  }
  backend "s3" {
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  region     = var.aws_region
  prefix     = "${var.project}-${var.environment}"
  account_id = data.aws_caller_identity.self.account_id
}

data "aws_caller_identity" "self" {}

resource "aws_s3_bucket" "lambda" {
  bucket        = "${local.prefix}-lambda"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "lambda" {
  bucket = aws_s3_bucket.lambda.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "lambda" {
  bucket                  = aws_s3_bucket.lambda.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "archive_file" "hello_function" {
  type        = "zip"
  source_dir  = "../../node/hello/dist"
  output_path = "lambda/hello_function.zip"
}

resource "aws_s3_object" "hello_function" {
  bucket = aws_s3_bucket.lambda.id

  key    = "hello_function.zip"
  source = data.archive_file.hello_function.output_path

  etag = filemd5(data.archive_file.hello_function.output_path)
}

data "aws_iam_policy_document" "lambda_assume_role" {
  version = "2012-10-17"

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "lambda_execution" {
  version = "2012-10-17"

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "cloudwatch:PutMetricData",
      "kms:*",
      "s3:*",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_execution" {
  name   = "${local.prefix}-lambda-execution"
  policy = data.aws_iam_policy_document.lambda_execution.json
}

resource "aws_iam_role" "lambda_execution" {
  name               = "${local.prefix}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy_attachment" "lambda_execution" {
  name = "${local.prefix}-lambda-execution"

  roles = [
    aws_iam_role.lambda_execution.name,
  ]

  policy_arn = aws_iam_policy.lambda_execution.arn
}

resource "aws_cloudwatch_log_group" "lambda_hello" {
  name              = "/aws/lambda/${local.prefix}-hello"
  retention_in_days = 3
}

resource "aws_lambda_function" "hello" {
  function_name = "${local.prefix}-hello"

  s3_bucket        = aws_s3_bucket.lambda.id
  s3_key           = aws_s3_object.hello_function.key
  source_code_hash = data.archive_file.hello_function.output_base64sha256

  handler = "lambda.handler"
  role    = aws_iam_role.lambda_execution.arn
  runtime = "nodejs16.x"

  depends_on = [
    aws_cloudwatch_log_group.lambda_hello,
  ]
}

resource "aws_lambda_function_url" "hello" {
  function_name      = aws_lambda_function.hello.function_name
  authorization_type = "NONE"
}
