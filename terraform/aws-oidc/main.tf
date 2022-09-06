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

data "aws_caller_identity" "self" {}

locals {
  region                 = var.aws_region
  prefix                 = "${var.project}-${var.environment}"
  account_id             = data.aws_caller_identity.self.account_id
  github_repository_name = var.github_repository_name
}

data "http" "github_actions_openid_configuration" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

data "tls_certificate" "github_actions" {
  url = jsondecode(data.http.github_actions_openid_configuration.body).jwks_uri
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = [
    "sts.amazonaws.com",
  ]
  thumbprint_list = [
    data.tls_certificate.github_actions.certificates[0].sha1_fingerprint,
  ]
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  version = "2012-10-17"

  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github_actions.arn,
      ]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.github_repository_name}:*",
      ]
    }
  }
}

data "aws_iam_policy_document" "github_actions" {
  version = "2012-10-17"

  statement {
    actions = [
      "lambda:*",
      "iam:*",
      "s3:*",
      "logs:*",
    ]
    effect  = "Allow"
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "github_actions" {
  name = "${local.prefix}-github-actions"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

resource "aws_iam_policy" "github_actions" {
  name = "${local.prefix}-github-actions"
  policy = data.aws_iam_policy_document.github_actions.json
}

resource "aws_iam_policy_attachment" "github_actions" {
  name = "${local.prefix}-github-actions"
  roles = [
    aws_iam_role.github_actions.name,
  ]
  policy_arn = aws_iam_policy.github_actions.arn
}
