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
| <a name="input_activate_ca"></a> [activate\_ca](#input\_activate\_ca) | n/a | `bool` | `false` | no |
| <a name="input_cert_chain"></a> [cert\_chain](#input\_cert\_chain) | n/a | `string` | `null` | no |
| <a name="input_crl_expiration_days"></a> [crl\_expiration\_days](#input\_crl\_expiration\_days) | n/a | `number` | `7` | no |
| <a name="input_crl_s3_bucket"></a> [crl\_s3\_bucket](#input\_crl\_s3\_bucket) | n/a | `string` | n/a | yes |
| <a name="input_enable_crl"></a> [enable\_crl](#input\_enable\_crl) | n/a | `bool` | `true` | no |
| <a name="input_key_algorithm"></a> [key\_algorithm](#input\_key\_algorithm) | Key algorithm for the CA | `string` | n/a | yes |
| <a name="input_root_ca_arn"></a> [root\_ca\_arn](#input\_root\_ca\_arn) | n/a | `string` | `null` | no |
| <a name="input_root_ca_validity_years"></a> [root\_ca\_validity\_years](#input\_root\_ca\_validity\_years) | n/a | `number` | `5` | no |
| <a name="input_signed_cert"></a> [signed\_cert](#input\_signed\_cert) | n/a | `string` | `null` | no |
| <a name="input_signing_algorithm"></a> [signing\_algorithm](#input\_signing\_algorithm) | n/a | `string` | `"SHA256WITHRSA"` | no |
| <a name="input_sub_ca_validity_years"></a> [sub\_ca\_validity\_years](#input\_sub\_ca\_validity\_years) | Validity period for subordinate CA (in years) | `number` | `3` | no |
| <a name="input_subject"></a> [subject](#input\_subject) | Certificate subject details | <pre>object({<br/>    common_name         = string<br/>    organization        = string<br/>    organizational_unit = string<br/>    country             = string<br/>    state               = string<br/>    locality            = string<br/>  })</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_type"></a> [type](#input\_type) | CA type: ROOT or SUBORDINATE | `string` | `"ROOT"` | no |
| <a name="input_usage_mode"></a> [usage\_mode](#input\_usage\_mode) | n/a | `string` | `"GENERAL_PURPOSE"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ca_arn"></a> [ca\_arn](#output\_ca\_arn) | ARN of the Private CA |
| <a name="output_csr"></a> [csr](#output\_csr) | CSR for subordinate CA |
