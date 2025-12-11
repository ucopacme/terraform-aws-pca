output "ca_arn" {
  description = "ARN of the Private CA"
  value       = aws_acmpca_certificate_authority.this.arn
}

output "csr" {
  description = "CSR for subordinate CA"
  value       = aws_acmpca_certificate_authority.this.certificate_signing_request
  sensitive   = true
}

