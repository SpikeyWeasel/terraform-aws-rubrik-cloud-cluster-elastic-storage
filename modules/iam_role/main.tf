locals {
  enable_immutability = var.enable_immutability != null ? var.enable_immutability : var.enableImmutability != null ? var.enableImmutability : false
}

data "aws_iam_policy_document" "assume_role" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "bucket" {
  count   = local.enable_immutability ? 0 : 1
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject*",
      "s3:GetObject*",
      "s3:ListMultipartUploadParts",
      "s3:PutObject*"
    ]
    resources = [
      "${var.bucket_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucket*",
      "s3:ListBucket*"
    ]
    resources = [
      var.bucket_arn
    ]
  }
}

data "aws_iam_policy_document" "immutable_bucket" {
  count   = local.enable_immutability ? 1 : 0
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject*",
      "s3:GetObject*",
      "s3:ListMultipartUploadParts",
      "s3:PutObject*"
    ]
    resources = [
      "${var.bucket_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucket*",
      "s3:ListBucket*",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetObjectLegalHold",
      "s3:GetObjectRetention",
      "s3:PutBucketObjectLockConfiguration",
      "s3:PutObjectLegalHold",
      "s3:PutObjectRetention"
    ]
    resources = [
      var.bucket_arn
    ]
  }
}

resource "aws_iam_role" "rubrik_ec2_s3" {
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  name                 = var.role_name
  permissions_boundary = var.role_permission_boundary
  tags                 = var.tags
}

resource "aws_iam_role_policy" "rubrik_ec2_s3_policy" {
  name   = var.role_policy_name
  policy = local.enable_immutability ? data.aws_iam_policy_document.immutable_bucket[0].json : data.aws_iam_policy_document.bucket[0].json
  role   = aws_iam_role.rubrik_ec2_s3.name
}

data "aws_iam_policy" "rubrik_ec2_s3_managed_policies" {
  for_each = var.role_managed_policies != null ? var.role_managed_policies : []
  arn      = each.value
}

resource "aws_iam_role_policy_attachment" "rubrik_ec2_s3_managed_policies" {
  for_each   = data.aws_iam_policy.rubrik_ec2_s3_managed_policies
  policy_arn = each.value.arn
  role       = aws_iam_role.rubrik_ec2_s3.name
}

resource "aws_iam_instance_profile" "rubrik_ec2_s3_profile" {
  name = var.instance_profile_name
  role = aws_iam_role.rubrik_ec2_s3.name
  tags = var.tags
}
