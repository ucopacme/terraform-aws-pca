data "aws_partition" "current" {}

# -------------------------
# Create the CA
# -------------------------
resource "aws_acmpca_certificate_authority" "this" {
  type = var.type

  certificate_authority_configuration {
    key_algorithm     = var.key_algorithm
    signing_algorithm = var.signing_algorithm

    subject {
      common_name         = var.subject.common_name
      organization        = var.subject.organization
      organizational_unit = var.subject.organizational_unit
      country             = var.subject.country
      state               = var.subject.state
      locality            = var.subject.locality
    }
  }

  revocation_configuration {
    crl_configuration {
      enabled            = var.enable_crl
      expiration_in_days = var.crl_expiration_days
      s3_bucket_name     = var.crl_s3_bucket
      s3_object_acl      = "BUCKET_OWNER_FULL_CONTROL"
    }
  }

  usage_mode = var.usage_mode
  tags       = var.tags
}

# -------------------------
# ROOT CA: Sign & install self-signed certificate
# -------------------------
resource "aws_acmpca_certificate" "activate_root" {
  count = var.type == "ROOT" ? 1 : 0

  certificate_authority_arn   = aws_acmpca_certificate_authority.this.arn
  certificate_signing_request = aws_acmpca_certificate_authority.this.certificate_signing_request
  signing_algorithm           = var.signing_algorithm

  template_arn = "arn:${data.aws_partition.current.partition}:acm-pca:::template/RootCACertificate/V1"

  validity {
    type  = var.sub_ca_validity_type
    value = var.root_ca_validity_years
  }
}

resource "aws_acmpca_certificate_authority_certificate" "install_root" {
  count = var.type == "ROOT" ? 1 : 0

  certificate_authority_arn = aws_acmpca_certificate_authority.this.arn
  certificate               = aws_acmpca_certificate.activate_root[0].certificate
  certificate_chain         = aws_acmpca_certificate.activate_root[0].certificate_chain
}

# -------------------------
# SUBORDINATE CA: Sign & install
# -------------------------
resource "aws_acmpca_certificate" "activate_sub_ca" {
  for_each = var.type == "SUBORDINATE" && var.root_ca_arn != "" ? { "sub" = 1 } : {}

  certificate_authority_arn   = var.root_ca_arn
  certificate_signing_request = aws_acmpca_certificate_authority.this.certificate_signing_request
  signing_algorithm           = var.signing_algorithm

  validity {
  type  = "YEARS"
  value = var.sub_ca_validity_years
}


  template_arn = "arn:${data.aws_partition.current.partition}:acm-pca:::template/SubordinateCACertificate_PathLen0/V1"
}

resource "aws_acmpca_certificate_authority_certificate" "install_cert" {
  count = var.type == "SUBORDINATE" && var.root_ca_arn != "" ? 1 : 0

  certificate_authority_arn = aws_acmpca_certificate_authority.this.arn
  certificate               = aws_acmpca_certificate.activate_sub_ca["sub"].certificate
  certificate_chain         = aws_acmpca_certificate.activate_sub_ca["sub"].certificate_chain
}

