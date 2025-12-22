variable "type" {
  description = "CA type: ROOT or SUBORDINATE"
  type        = string
  default     = "ROOT"
}

variable "key_algorithm" {
  description = "Key algorithm for the CA"
  type        = string
  default     = null 

  validation {
    # If null, it's valid (because we're using sub-level config). 
    # If NOT null, it must be in the list.
    condition = var.key_algorithm == null ? true : contains([
      "ML-DSA-44", "ML-DSA-65", "ML-DSA-87",
      "RSA_2048", "RSA_3072", "RSA_4096",
      "ECDSA_P256", "ECDSA_P384", "ECDSA_P521"
    ], var.key_algorithm)

    error_message = "Invalid key_algorithm provided."
  }
}

variable "subject" {
  description = "Subject for root CA"
  type = object({
    common_name         = string
    organization        = string
    organizational_unit = string
    country             = string
    state               = string
    locality            = string
  })
  default = null 
}

# Do the same for any other erroring variables (e.g., signing_algorithm)
variable "signing_algorithm" {
  type    = string
  default = "SHA256WITHRSA" # This already has a default, so it shouldn't error
}





# Per-subordinate CA OCSP
variable "subordinate_cas" {
  type = map(object({
    subject = object({
      common_name         = string
      organization        = string
      organizational_unit = string
      country             = string
      state               = string
      locality            = string
    })
    key_algorithm         = optional(string, "RSA_2048")
    signing_algorithm     = optional(string, "SHA256WITHRSA")
    usage_mode            = optional(string, "GENERAL_PURPOSE")
    activate_ca           = optional(bool, true)
    enable_crl            = optional(bool, true)
    crl_expiration_days   = optional(number, 7)
    crl_s3_bucket         = string
    crl_custom_name       = optional(string, null)
    enable_ocsp           = optional(bool, false)
    tags                  = optional(map(string), {})
    sub_ca_validity_type  = string
    sub_ca_validity_value = number
  }))
  default = {}
}


variable "enable_crl" {
  type    = bool
  default = true
}



variable "crl_s3_bucket" {
  type    = string
  default = ""
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

# Global toggle for root CA
variable "enable_ocsp" {
  description = "Enable OCSP for root CA"
  type        = bool
  default     = false
}


variable "crl_custom_name" {
  description = "Optional custom CRL file name"
  type        = string
  default     = null
}

variable "crl_expiration_days" {
  description = "CRL validity period in days"
  type        = number
  default     = 7
}

variable "partitioned_crl" {
  description = "Partitioned CRL enabled or disabled"
  type        = bool
  default     = false
}

variable "ocsp_custom_url" {
  description = "Optional custom OCSP URL"
  type        = string
  default     = null
}

variable "permanent_deletion_time_in_days" {
  type        = number
  description = "Days before ACM PCA permanently deletes the CA after deletion"
  default     = 30
}
