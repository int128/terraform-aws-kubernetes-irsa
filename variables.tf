variable "oidc_s3_bucket_name" {
  description = "Name of a S3 bucket for the OIDC endpoint"
}

variable "oidc_jwks_filename" {
  description = "Filename of OIDC JWKS"
}

variable "oidc_ca_sha1" {
  description = "SHA1 thumbprint of the root CA certificate (default to *.s3.amazonaws.com)"
  default     = "3fe05b486e3f0987130ba1d4ea0f299539a58243"
}

variable "signer_public_key_filename" {
  description = "Filename of the private key (for kops_cluster.yaml)"
  default     = "/dev/null"
}

variable "signer_private_key_filename" {
  description = "Filename of the private key (for kops_cluster.yaml)"
  default     = "/dev/null"
}
