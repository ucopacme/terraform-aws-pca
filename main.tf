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
  permanent_deletion_time_in_days = var.permanent_deletion_time_in_days
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
      custom_cname       = var.crl_custom_name

    }

    ocsp_configuration {
      enabled = var.enable_ocsp

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
# SUBORDINATE CAs
# -------------------------
resource "aws_acmpca_certificate_authority" "subordinate" {
  for_each = var.type == "SUBORDINATE" ? var.subordinate_cas : {}

  type       = "SUBORDINATE"
  usage_mode = each.value.usage_mode
  tags       = each.value.tags
   permanent_deletion_time_in_days = var.permanent_deletion_time_in_days
  certificate_authority_configuration {
    # CHANGE: Use map value, not var.key_algorithm
    key_algorithm     = each.value.key_algorithm
    signing_algorithm = each.value.signing_algorithm

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
      enabled            = each.value.enable_crl
      expiration_in_days = each.value.crl_expiration_days
      s3_bucket_name     = each.value.crl_s3_bucket
      s3_object_acl      = "BUCKET_OWNER_FULL_CONTROL"
      custom_cname       = each.value.crl_custom_name
    }
    ocsp_configuration {
      enabled = each.value.enable_ocsp
    }
  }
}

# -------------------------
# SUBORDINATE Certificates: Signed by ROOT
# -------------------------
resource "aws_acmpca_certificate" "activate_sub_ca" {
  # We use the same map as the CA to ensure keys match
  for_each = var.type == "SUBORDINATE" && var.activate_ca ? var.subordinate_cas : {}

  certificate_authority_arn   = var.root_ca_arn
  certificate_signing_request = aws_acmpca_certificate_authority.subordinate[each.key].certificate_signing_request
 
  
  # CHANGE: This MUST match the algorithm defined in the CA configuration above
  signing_algorithm = each.value.signing_algorithm

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
  for_each = var.type == "SUBORDINATE" && var.activate_ca ? var.subordinate_cas : {}

  certificate_authority_arn = aws_acmpca_certificate_authority.subordinate[each.key].arn
  
  # Reference the specific certificate generated in the step above
  certificate               = aws_acmpca_certificate.activate_sub_ca[each.key].certificate
  certificate_chain         = aws_acmpca_certificate.activate_sub_ca[each.key].certificate_chain
}