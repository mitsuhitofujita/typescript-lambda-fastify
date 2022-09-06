terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.27.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "self" {}

locals {
  region     = var.aws_region
  prefix     = "${var.project}-${var.environment}"
  account_id = data.aws_caller_identity.self.account_id
}

resource "aws_s3_bucket" "backend" {
  bucket = "${local.prefix}-terraform-backend"
}

resource "aws_s3_bucket_acl" "backend" {
  bucket = aws_s3_bucket.backend.id
  acl    = "private"
}
