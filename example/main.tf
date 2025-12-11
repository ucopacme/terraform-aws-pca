### S3 Deployment
data "aws_caller_identity" "current" {}

locals {
  bucket_name = join("-", [local.application, local.environment, data.aws_caller_identity.current.account_id])
}

module "s3" {
  source         = "git::https://git@github.com/ucopacme/terraform-aws-s3-multi-use-bucket.git//?ref=v0.0.6"
  bucket         = local.bucket_name
  enabled        = true
  policy         = data.aws_iam_policy_document.this.json
  policy_enabled = true
  sse_algorithm                 = "AES256"
  enable_standard_ia_transition = false
  tags = {
    "Name"             = local.bucket_name
  }
}

data "aws_iam_policy_document" "this" {
  # Deny non-SSL
  statement {
    sid    = "AllowSSLRequestsOnly"
    effect = "Deny"

    resources = [
      "arn:aws:s3:::${local.bucket_name}",
      "arn:aws:s3:::${local.bucket_name}/*",
    ]

    actions = ["s3:*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  # Bucket-level permissions for PCA
  statement {
    sid    = "AllowQrdrBucketActionsBucketLevel"
    effect = "Allow"

    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}",
    ]

    principals {
      type = "Service"
      identifiers = [
        "acm-pca.amazonaws.com",
      ]
    }
  }

  # Object-level permissions for PCA
  statement {
    sid    = "AllowQrdrBucketActionsObjectLevel"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/*",
    ]

    principals {
      type = "Service"
      identifiers = [
        "acm-pca.amazonaws.com",
      ]
    }
  }
}



resource "null_resource" "wait_for_s3" {
  depends_on = [module.s3] # Wait for S3 module to finish

  provisioner "local-exec" {
    command = "sleep 10" # Wait 10 seconds
  }
}

### root
module "pqc_ca" {
  source = "git::https://git@github.com/ucopacme/terraform-aws-pca.git//"

  type                   = "ROOT"
  key_algorithm          = "RSA_2048"
  signing_algorithm      = "SHA256WITHRSA"
  root_ca_validity_years = 5
  subject                = local.root_ca_subject
  crl_s3_bucket          = local.bucket_name

  # Optional: if you use it to wait until bucket is ready
  depends_on = [null_resource.wait_for_s3]
}

### sub

module "pqc_sub_cas" {
  source = "git::https://git@github.com/ucopacme/terraform-aws-pca.git//"

  for_each = local.subordinate_cas

  type              = "SUBORDINATE"
  key_algorithm     = "RSA_2048"
  signing_algorithm = "SHA256WITHRSA"

  subject = each.value.subject

  crl_s3_bucket = local.bucket_name
  root_ca_arn   = module.pqc_ca.ca_arn

}