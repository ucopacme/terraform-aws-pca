data "aws_partition" "current" {}

# -------------------------
# Create the CA
# -------------------------
resource "aws_acmpca_certificate_authority" "this" {
  for_each = var.type == "SUBORDINATE" && length(var.subordinate_cas) > 0 ? var.subordinate_cas : {}

  type = "SUBORDINATE"

  certificate_authority_configuration {
    key_algorithm     = var.key_algorithm
    signing_algorithm = var.signing_algorithm

    subject {
      common_name         = each.value.subject.common_name
      organization        = each.value.subject.organization
      organizational_unit = lookup(each.value.subject, "organizational_unit", "")
      country             = each.value.subject.country
      state               = each.value.subject.state
      locality            = lookup(each.value.subject, "locality", "")
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
    type  = "YEARS"
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
  for_each = aws_acmpca_certificate_authority.subordinate

  certificate_authority_arn   = var.root_ca_arn
  certificate_signing_request = each.value.certificate_signing_request
  signing_algorithm           = var.signing_algorithm

  validity {
    type  = lookup(var.subordinate_cas[each.key], "sub_ca_validity_type", "YEARS")
    value = lookup(var.subordinate_cas[each.key], "sub_ca_validity_value", 5)
  }

  template_arn = "arn:${data.aws_partition.current.partition}:acm-pca:::template/SubordinateCACertificate_PathLen0/V1"
}


resource "aws_acmpca_certificate_authority_certificate" "install_cert" {
  for_each = aws_acmpca_certificate.activate_sub_ca

  certificate_authority_arn = aws_acmpca_certificate_authority.subordinate[each.key].arn
  certificate               = each.value.certificate
  certificate_chain         = each.value.certificate_chain
}

