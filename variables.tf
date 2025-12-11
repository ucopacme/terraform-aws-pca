variable "type" {
  description = "Specifies the type of Private CA to create. Valid values are ROOT or SUBORDINATE."
  type        = string
  default     = "ROOT"
}

variable "key_algorithm" {
  description = "The algorithm used to generate the CA's private key. Supported values include ML-DSA (quantum-resistant), RSA, and ECDSA key types."
  type        = string

  validation {
    condition = contains([
      "ML-DSA-44", "ML-DSA-65", "ML-DSA-87",
      "RSA_2048", "RSA_3072", "RSA_4096",
      "ECDSA_P256", "ECDSA_P384", "ECDSA_P521"
    ], var.key_algorithm)

    error_message = "Invalid key_algorithm"
  }
}

variable "signing_algorithm" {
  description = "The signature algorithm used by the CA when signing certificates. Defaults to SHA256WITHRSA."
  type        = string
  default     = "SHA256WITHRSA"
}

# --------------------------------
# NEW: Single subject object
# --------------------------------
variable "subject" {
  description = "Distinguished Name (DN) attributes for the CA certificate, such as CN, organization, and location fields."
  type = object({
    common_name         = string
    organization        = string
    organizational_unit = string
    country             = string
    state               = string
    locality            = string
  })
}

variable "enable_crl" {
  description = "Enables or disables CRL (Certificate Revocation List) publishing for the CA."
  type        = bool
  default     = true
}

variable "crl_expiration_days" {
  description = "Number of days before the published CRL expires and must be refreshed."
  type        = number
  default     = 7
}

variable "crl_s3_bucket" {
  description = "Name of the S3 bucket where CRLs (Certificate Revocation Lists) will be stored."
  type        = string
}

variable "usage_mode" {
  description = "Defines the intended usage mode for the CA. Valid values include GENERAL_PURPOSE or SHORT_LIVED_CERTIFICATE."
  type        = string
  default     = "GENERAL_PURPOSE"
}

variable "tags" {
  description = "Optional tags to apply to all created AWS resources."
  type        = map(string)
  default     = {}
}

variable "activate_ca" {
  description = "Controls whether the CA should be activated after creation. Set to true only when certificate signing material is provided."
  type        = bool
  default     = false
}

variable "signed_cert" {
  description = "The signed certificate for activating the CA (used for subordinate CAs). Leave null for ROOT CA creation."
  type        = string
  default     = null
}

variable "cert_chain" {
  description = "The certificate chain associated with the signed certificate for CA activation. Used for subordinate CAs."
  type        = string
  default     = null
}

variable "root_ca_validity_years" {
  description = "Validity period (in years) for the Root CA certificate."
  type        = number
  default     = 5
}

variable "root_ca_arn" {
  description = "ARN of the Root CA used to sign a subordinate CA certificate. Required only when type = SUBORDINATE."
  type        = string
  default     = null
}

variable "sub_ca_validity_years" {
  description = "Validity period (in years) for the Subordinate CA certificate."
  type        = number
  default     = 3
}
