# -------------------------
# Data: Current AWS Partition
# -------------------------
data "aws_partition" "current" {}

# -------------------------
# ROOT CA: Single Resource
# -------------------------
resource "aws_acmpca_certificate_authority" "root" {
  count = var.type == "ROOT" ? 1 : 0

  type = "ROOT"

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
# ROOT CA: Self-signed Certificate
# -------------------------
resource "aws_acmpca_certificate" "activate_root" {
  count = var.type == "ROOT" && var.activate_ca ? 1 : 0

  certificate_authority_arn   = aws_acmpca_certificate_authority.root[0].arn
  certificate_signing_request = aws_acmpca_certificate_authority.root[0].certificate_signing_request
  signing_algorithm           = var.signing_algorithm

  template_arn = "arn:${data.aws_partition.current.partition}:acm-pca:::template/RootCACertificate/V1"

  validity {
    type  = "YEARS"
    value = var.root_ca_validity_years
  }
}

resource "aws_acmpca_certificate_authority_certificate" "install_root" {
  count = var.type == "ROOT" && var.activate_ca ? 1 : 0

  certificate_authority_arn = aws_acmpca_certificate_authority.root[0].arn
  certificate               = aws_acmpca_certificate.activate_root[0].certificate
  certificate_chain         = aws_acmpca_certificate.activate_root[0].certificate_chain
}

# -------------------------
# SUBORDINATE CAs: One CA per subordinate
# -------------------------
resource "aws_acmpca_certificate_authority" "subordinate" {
  for_each = var.type == "SUBORDINATE" && var.activate_ca && var.root_ca_arn != null
    ? var.subordinate_cas
    : {}

  type = "SUBORDINATE"

  certificate_authority_configuration {
    key_algorithm     = var.key_algorithm
    signing_algorithm = var.signing_algorithm

    subject {
      common_name         = each.value.subject.common_name
      organization        = each.value.subject.organization
      organizational_unit = each.value.subject.organizational_unit
      country             = each.value.subject.country
      state               = each.value.subject.state
      locality            = each.value.subject.locality
    }
  }

  revocation_configuration {
    crl_configuration {
      enabled            = var.enable_crl
      expiration_in_days = var.crl_expiration_days

      # per-subordinate bucket override
      s3_bucket_name = coalesce(
        each.value.crl_s3_bucket,
        var.crl_s3_bucket
      )

      s3_object_acl = "BUCKET_OWNER_FULL_CONTROL"
    }
  }

  usage_mode = var.usage_mode
  tags       = var.tags
}


# -------------------------
# SUBORDINATE Certificates: Signed by ROOT
# -------------------------
resource "aws_acmpca_certificate" "activate_sub_ca" {
  for_each = var.type == "SUBORDINATE" && var.activate_ca && var.root_ca_arn != null ? var.subordinate_cas : {}

  certificate_authority_arn   = var.root_ca_arn
  certificate_signing_request = aws_acmpca_certificate_authority.subordinate[each.key].certificate_signing_request
  signing_algorithm           = var.signing_algorithm

  validity {
    type  = upper(each.value.sub_ca_validity_type)
    value = each.value.sub_ca_validity_value
  }

  template_arn = "arn:${data.aws_partition.current.partition}:acm-pca:::template/SubordinateCACertificate_PathLen0/V1"
}

# -------------------------
# Install Subordinate Certificates
# -------------------------
resource "aws_acmpca_certificate_authority_certificate" "install_sub_cert" {
  for_each = var.type == "SUBORDINATE" && var.activate_ca && var.root_ca_arn != null ? var.subordinate_cas : {}

  certificate_authority_arn = aws_acmpca_certificate_authority.subordinate[each.key].arn
  certificate               = aws_acmpca_certificate.activate_sub_ca[each.key].certificate
  certificate_chain         = aws_acmpca_certificate.activate_sub_ca[each.key].certificate_chain
}
