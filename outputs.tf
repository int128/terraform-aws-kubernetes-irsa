output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = aws_iam_openid_connect_provider.irsa.arn
}

output "oidc_issuer" {
  description = "Domain name of the S3 bucket (*.s3.amazonaws.com)"
  value       = aws_s3_bucket.oidc.bucket_domain_name
}

output "pod_identity_webhook_ecr_repository_url" {
  description = "URL to the ECR repository for eks/pod-identity-webhook"
  value       = aws_ecr_repository.pod_identity_webhook.repository_url
}

output "kops_cluster_yaml" {
  description = "Content of kops cluster.yaml"
  value       = <<EOF
spec:
  fileAssets:
  - content: {base64 sa-signer.key}
    isBase64: true
    name: service-account-signing-key-file
    path: /srv/kubernetes/assets/service-account-signing-key
  - content: {base64 sa-signer-pkcs8.pub}
    isBase64: true
    name: service-account-key-file
    path: /srv/kubernetes/assets/service-account-key
  kubeAPIServer:
    apiAudiences:
    - sts.amazonaws.com
    serviceAccountIssuer: https://${aws_s3_bucket.oidc.bucket_domain_name}
    serviceAccountKeyFile:
    - /srv/kubernetes/server.key
    - /srv/kubernetes/assets/service-account-key
    serviceAccountSigningKeyFile: /srv/kubernetes/assets/service-account-signing-key
EOF
}
