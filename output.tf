output "root_ca_arn" {
  description = "ARN of the root CA (only for ROOT type)"
  value       = try(aws_acmpca_certificate_authority.root[0].arn, null)
}

output "root_ca_csr" {
  description = "CSR of the root CA (only for ROOT type)"
  value       = try(
    aws_acmpca_certificate_authority.root[0].certificate_signing_request,
    null
  )
}

output "subordinate_ca_arns" {
  description = "Map of subordinate CA ARNs"
  value = {
    for k, ca in aws_acmpca_certificate_authority.subordinate :
    k => ca.arn
  }
}
