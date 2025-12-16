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
resource "aws_acmpca_certificate_authority" "subordinate" {
  for_each = var.type == "SUBORDINATE" ? var.subordinate_cas : {}

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
      enabled            = lookup(each.value, "enable_crl", var.enable_crl)
      expiration_in_days = lookup(each.value, "crl_expiration_days", var.crl_expiration_days)
      s3_bucket_name     = coalesce(each.value.crl_s3_bucket, var.crl_s3_bucket)
      s3_object_acl      = "BUCKET_OWNER_FULL_CONTROL"
      custom_cname       = lookup(each.value, "crl_custom_name", var.crl_custom_name)

    }

    ocsp_configuration {
      enabled = lookup(each.value, "enable_ocsp", var.enable_ocsp)

    }
  }
}




# -------------------------
# SUBORDINATE Certificates: Signed by ROOT
# -------------------------
resource "aws_acmpca_certificate" "activate_sub_ca" {
  for_each = var.type == "SUBORDINATE" && var.activate_ca ? var.subordinate_cas : {}

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
  for_each = var.type == "SUBORDINATE" && var.activate_ca ? var.subordinate_cas : {}

  certificate_authority_arn = aws_acmpca_certificate_authority.subordinate[each.key].arn
  certificate               = aws_acmpca_certificate.activate_sub_ca[each.key].certificate
  certificate_chain         = aws_acmpca_certificate.activate_sub_ca[each.key].certificate_chain
}


# -------------------------
# Permissions: Allow SCEP Connector
# -------------------------

# -------------------------
# Permissions: Final Corrected Resource Policy
# -------------------------

data "aws_caller_identity" "current" {}

# Policy for ROOT CA
resource "aws_acmpca_policy" "root_scep_policy" {
  count        = var.type == "ROOT" ? 1 : 0
  resource_arn = aws_acmpca_certificate_authority.root[0].arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowSCEPConnector"
      Effect = "Allow"
      Principal = {
        Service = "pca-connector-scep.amazonaws.com"
      }
      Action = [
        "acm-pca:IssueCertificate",
        "acm-pca:GetCertificate",
        "acm-pca:ListPermissions"
      ]
      Resource = aws_acmpca_certificate_authority.root[0].arn
      # THIS CONDITION IS THE FIX
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })
}

# Policy for SUBORDINATE CAs
resource "aws_acmpca_policy" "subordinate_scep_policy" {
  for_each     = var.type == "SUBORDINATE" ? var.subordinate_cas : {}
  resource_arn = aws_acmpca_certificate_authority.subordinate[each.key].arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowSCEPConnector"
      Effect = "Allow"
      Principal = {
        Service = "pca-connector-scep.amazonaws.com"
      }
      Action = [
        "acm-pca:IssueCertificate",
        "acm-pca:GetCertificate",
        "acm-pca:ListPermissions"
      ]
      Resource = aws_acmpca_certificate_authority.subordinate[each.key].arn
      # THIS CONDITION IS THE FIX
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })
}