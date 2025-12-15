variable "type" {
  description = "CA type: ROOT or SUBORDINATE"
  type        = string
  default     = "ROOT"
}

variable "key_algorithm" {
  description = "Key algorithm for the CA"
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
  type    = string
  default = "SHA256WITHRSA"
}
variable "subject" {
  description = "Subject for the main/root CA"
  type = object({
    common_name         = string
    organization        = string
    organizational_unit = string
    country             = string
    state               = string
    locality            = string
  })
}

# --------------------------------
# NEW: Single subject object
# --------------------------------
variable "subordinate_cas" {
  description = "Map of subordinate CAs to create. Each key is an identifier."
  type = map(object({
    subject = object({
      common_name         = string
      organization        = string
      organizational_unit = string
      country             = string
      state               = string
      locality            = string
    })
    sub_ca_validity_type  = string
    sub_ca_validity_value = number
    crl_s3_bucket         = optional(string, "") # optional, for different CRLs
  }))
  default = {}
}


variable "enable_crl" {
  type    = bool
  default = true
}

variable "crl_expiration_days" {
  type    = number
  default = 7
}

variable "crl_s3_bucket" {
  type = string
}

variable "usage_mode" {
  type    = string
  default = "GENERAL_PURPOSE"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "activate_ca" {
  type    = bool
  default = false
}

variable "signed_cert" {
  type    = string
  default = null
}

variable "cert_chain" {
  type    = string
  default = null
}

variable "root_ca_validity_years" {
  type    = number
  default = 5
}

variable "root_ca_arn" {
  type    = string
  default = null
}

variable "sub_ca_validity_years" {
  description = "Validity period for subordinate CA (in years)"
  type        = number
  default     = 3
}