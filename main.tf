# main.tf

provider "aws" {
  region = "us-west-2"
}

# Create IAM SAML provider for Okta
resource "aws_iam_saml_provider" "okta" {
  name                   = "okta-idp"
  saml_metadata_document = file("okta-metadata.xml")  # You'll need to download this from Okta

  tags = {
    Environment = "all"
    Purpose     = "identity-provider"
  }
}

# Create IAM role for Okta federation
resource "aws_iam_role" "okta_sso" {
  name = "okta-sso-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_saml_provider.okta.arn
        }
        Action = "sts:AssumeRoleWithSAML"
        Condition = {
          StringEquals = {
            "SAML:aud": "https://signin.aws.amazon.com/saml"
          }
        }
      }
    ]
  })

  # Add tags that will be used for ABAC
  tags = {
    Purpose = "federation"
  }
}

# Create IAM groups for different teams
resource "aws_iam_group" "teams" {
  for_each = toset(["development", "production", "staging"])
  name     = "team-${each.key}"
}

# Create role for dynamic access
resource "aws_iam_role" "abac_role" {
  name = "abac-dynamic-access-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.okta_sso.arn
        }
      }
    ]
  })

  # ABAC policy that uses tags for access control
  inline_policy {
    name = "abac-resource-access"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket"
          ]
          Resource = "*"
          Condition = {
            StringEquals = {
              "aws:ResourceTag/Environment": "${aws:PrincipalTag/Environment}",
              "aws:ResourceTag/Team": "${aws:PrincipalTag/Team}"
            }
          }
        },
        {
          Effect = "Allow"
          Action = [
            "ec2:StartInstances",
            "ec2:StopInstances"
          ]
          Resource = "*"
          Condition = {
            StringEquals = {
              "aws:ResourceTag/Environment": "${aws:PrincipalTag/Environment}",
              "aws:ResourceTag/Team": "${aws:PrincipalTag/Team}"
            }
          }
        }
      ]
    })
  }
}

# Create example S3 bucket with tags
resource "aws_s3_bucket" "team_buckets" {
  for_each = toset(["development", "production", "staging"])
  
  bucket = "example-${each.key}-bucket"
  
  tags = {
    Team        = each.key
    Environment = each.key == "development" ? "dev" : each.key
  }
}

# Example EC2 instance with tags
resource "aws_instance" "team_instances" {
  for_each = {
    "development" = { instance_type = "t2.micro", environment = "dev" }
    "production"  = { instance_type = "t2.small", environment = "prod" }
    "staging"     = { instance_type = "t2.micro", environment = "staging" }
  }
  
  ami           = "ami-0c55b159cbfafe1f0" # Replace with valid AMI ID
  instance_type = each.value.instance_type
  
  tags = {
    Team        = each.key
    Environment = each.value.environment
  }
}

# Outputs
output "okta_role_arn" {
  value = aws_iam_role.okta_sso.arn
}

output "saml_provider_arn" {
  value = aws_iam_saml_provider.okta.arn
}

output "abac_role_arn" {
  value = aws_iam_role.abac_role.arn
}
