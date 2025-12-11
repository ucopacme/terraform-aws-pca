## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acmpca_certificate.activate_root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acmpca_certificate) | resource |
| [aws_acmpca_certificate.activate_sub_ca](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acmpca_certificate) | resource |
| [aws_acmpca_certificate_authority.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acmpca_certificate_authority) | resource |
| [aws_acmpca_certificate_authority_certificate.install_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acmpca_certificate_authority_certificate) | resource |
| [aws_acmpca_certificate_authority_certificate.install_root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acmpca_certificate_authority_certificate) | resource |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_activate_ca"></a> [activate\_ca](#input\_activate\_ca) | Controls whether the CA should be activated after creation. Set to true only when certificate signing material is provided. | `bool` | `false` | no |
| <a name="input_cert_chain"></a> [cert\_chain](#input\_cert\_chain) | The certificate chain associated with the signed certificate for CA activation. Used for subordinate CAs. | `string` | `null` | no |
| <a name="input_crl_expiration_days"></a> [crl\_expiration\_days](#input\_crl\_expiration\_days) | Number of days before the published CRL expires and must be refreshed. | `number` | `7` | no |
| <a name="input_crl_s3_bucket"></a> [crl\_s3\_bucket](#input\_crl\_s3\_bucket) | Name of the S3 bucket where CRLs (Certificate Revocation Lists) will be stored. | `string` | n/a | yes |
| <a name="input_enable_crl"></a> [enable\_crl](#input\_enable\_crl) | Enables or disables CRL (Certificate Revocation List) publishing for the CA. | `bool` | `true` | no |
| <a name="input_key_algorithm"></a> [key\_algorithm](#input\_key\_algorithm) | The algorithm used to generate the CA's private key. Supported values include ML-DSA (quantum-resistant), RSA, and ECDSA key types. | `string` | n/a | yes |
| <a name="input_root_ca_arn"></a> [root\_ca\_arn](#input\_root\_ca\_arn) | ARN of the Root CA used to sign a subordinate CA certificate. Required only when type = SUBORDINATE. | `string` | `null` | no |
| <a name="input_root_ca_validity_years"></a> [root\_ca\_validity\_years](#input\_root\_ca\_validity\_years) | Validity period (in years) for the Root CA certificate. | `number` | `5` | no |
| <a name="input_signed_cert"></a> [signed\_cert](#input\_signed\_cert) | The signed certificate for activating the CA (used for subordinate CAs). Leave null for ROOT CA creation. | `string` | `null` | no |
| <a name="input_signing_algorithm"></a> [signing\_algorithm](#input\_signing\_algorithm) | The signature algorithm used by the CA when signing certificates. Defaults to SHA256WITHRSA. | `string` | `"SHA256WITHRSA"` | no |
| <a name="input_sub_ca_validity_years"></a> [sub\_ca\_validity\_years](#input\_sub\_ca\_validity\_years) | Validity period (in years) for the Subordinate CA certificate. | `number` | `3` | no |
| <a name="input_subject"></a> [subject](#input\_subject) | Distinguished Name (DN) attributes for the CA certificate, such as CN, organization, and location fields. | <pre>object({<br/>    common_name         = string<br/>    organization        = string<br/>    organizational_unit = string<br/>    country             = string<br/>    state               = string<br/>    locality            = string<br/>  })</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Optional tags to apply to all created AWS resources. | `map(string)` | `{}` | no |
| <a name="input_type"></a> [type](#input\_type) | Specifies the type of Private CA to create. Valid values are ROOT or SUBORDINATE. | `string` | `"ROOT"` | no |
| <a name="input_usage_mode"></a> [usage\_mode](#input\_usage\_mode) | Defines the intended usage mode for the CA. Valid values include GENERAL\_PURPOSE or SHORT\_LIVED\_CERTIFICATE. | `string` | `"GENERAL_PURPOSE"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ca_arn"></a> [ca\_arn](#output\_ca\_arn) | ARN of the Private CA |
| <a name="output_csr"></a> [csr](#output\_csr) | CSR for subordinate CA |
