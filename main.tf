resource "aws_s3_bucket" "oidc" {
  bucket = var.oidc_s3_bucket_name
  acl    = "private"
}

resource "aws_s3_bucket_object" "oidc_discovery" {
  bucket  = var.oidc_s3_bucket_name
  key     = "/.well-known/openid-configuration"
  acl     = "public-read"
  content = <<EOF
{
  "issuer": "https://${aws_s3_bucket.oidc.bucket_domain_name}/",
  "jwks_uri": "https://${aws_s3_bucket.oidc.bucket_domain_name}/jwks.json",
  "authorization_endpoint": "urn:kubernetes:programmatic_authorization",
  "response_types_supported": [
    "id_token"
  ],
  "subject_types_supported": [
    "public"
  ],
  "id_token_signing_alg_values_supported": [
    "RS256"
  ],
  "claims_supported": [
    "sub",
    "iss"
  ]
}
EOF
}

resource "aws_s3_bucket_object" "oidc_jwks" {
  bucket = var.oidc_s3_bucket_name
  key    = "/jwks.json"
  acl    = "public-read"
  source = var.oidc_jwks_filename
}

resource "aws_iam_openid_connect_provider" "irsa" {
  url             = "https://${aws_s3_bucket.oidc.bucket_domain_name}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.oidc_ca_sha1]
}

resource "aws_ecr_repository" "pod_identity_webhook" {
  name = "eks/pod-identity-webhook"
}

data "aws_region" "current" {}

resource "aws_codebuild_project" "pod_identity_webhook" {
  name         = "pod-identity-webhook"
  description  = "Build https://github.com/aws/amazon-eks-pod-identity-webhook"
  service_role = aws_iam_role.codebuild_pod_identity_webhook.arn

  source {
    type      = "GITHUB"
    location  = "https://github.com/aws/amazon-eks-pod-identity-webhook.git"
    buildspec = <<EOF
version: 0.2
phases:
  build:
    commands:
    - make push REGION=${data.aws_region.current.name} REGISTRY_ID=${aws_ecr_repository.pod_identity_webhook.registry_id} IMAGE_NAME=${aws_ecr_repository.pod_identity_webhook.name}
EOF
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true # for docker build
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }
}

resource "aws_iam_role" "codebuild_pod_identity_webhook" {
  name               = "codebuild_pod_identity_webhook"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_pod_identity_webhook" {
  role   = aws_iam_role.codebuild_pod_identity_webhook.name
  policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement": [
    {
      "Sid": "CloudWatchLogsPolicy",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Sid":"ListImagesInRepository",
      "Effect":"Allow",
      "Action":[
        "ecr:ListImages"
      ],
      "Resource":"${aws_ecr_repository.pod_identity_webhook.arn}"
    },
    {
      "Sid":"GetAuthorizationToken",
      "Effect":"Allow",
      "Action":[
        "ecr:GetAuthorizationToken"
      ],
      "Resource":"*"
    },
    {
      "Sid":"ManageRepositoryContents",
      "Effect":"Allow",
      "Action":[
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:DescribeImages",
            "ecr:BatchGetImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:PutImage"
      ],
      "Resource":"${aws_ecr_repository.pod_identity_webhook.arn}"
    }
  ]
}
EOF
}
