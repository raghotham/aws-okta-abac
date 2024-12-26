# AWS OKTA ABAC System

This repository contains Infrastructure as Code (IaC) for implementing an Attribute-Based Access Control (ABAC) system in AWS using Okta as a SAML 2.0 identity provider. The system provides fine-grained access control based on user and resource attributes.

## Prerequisites

- AWS Account with administrative access
- Okta Administrator access
- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials
- Git

## Architecture Overview

The system implements:
- SAML 2.0 federation with Okta
- Attribute-based access control using AWS tags
- Team-based resource segregation
- Environment-based access control (dev/staging/prod)
- S3 bucket and EC2 instance management

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/YOUR-USERNAME/aws-okta-abac.git
cd aws-okta-abac
```

2. Configure Okta (Prerequisites):
   - Log into your Okta Admin Console
   - Navigate to Applications > Applications > Create App Integration
   - Select SAML 2.0 as the sign-in method
   - Download the IdP metadata XML file
   - Save it as `okta-metadata.xml` in the project root

3. Update Configuration:
   - Create a `terraform.tfvars` file:
```hcl
aws_region = "us-west-2"  # Your preferred region
aws_account_id = "123456789012"  # Your AWS account ID
okta_org_id = "your-okta-org-id"
```

4. Initialize and Apply Terraform:
```bash
terraform init
terraform plan
terraform apply
```

## Okta Configuration

1. Create the AWS App in Okta:
   - Use the `okta-app-config.json` file as a reference
   - Set the ACS URL to: https://signin.aws.amazon.com/saml
   - Configure SAML attribute statements:
     - Role: `https://aws.amazon.com/SAML/Attributes/Role`
     - RoleSessionName: `https://aws.amazon.com/SAML/Attributes/RoleSessionName`
     - Team: Custom attribute mapping
     - Environment: Custom attribute mapping

2. Configure Group Assignments:
   - Create groups in Okta matching your teams
   - Assign users to appropriate groups
   - Map groups to AWS roles in the app configuration

## AWS Resource Configuration

The system creates:

1. S3 Buckets:
   - One bucket per team/environment
   - Tagged with appropriate team and environment values

2. EC2 Instances:
   - Sample instances for each environment
   - Tagged with team and environment attributes

3. IAM Roles:
   - SAML provider role for Okta integration
   - ABAC roles for resource access
   - Team-specific roles with appropriate permissions

## Security Considerations

1. Tag Management:
   - Implement tag validation
   - Regular tag audit procedures
   - Automated tag compliance checking

2. Access Reviews:
   - Regular role and permission reviews
   - Session duration monitoring
   - Access pattern analysis

3. Best Practices:
   - Enable AWS CloudTrail
   - Implement AWS Organizations
   - Use AWS KMS for encryption
   - Regular security assessments

## Customization

### Adding New Teams

1. Add new team to the teams variable in `main.tf`:
```hcl
locals {
  teams = ["development", "production", "staging", "new-team"]
}
```

2. Create corresponding Okta groups and attribute mappings

### Modifying Permissions

1. Update the ABAC role policy in `main.tf`:
```hcl
inline_policy {
  name = "abac-resource-access"
  policy = jsonencode({
    # Add or modify permissions here
  })
}
```

## Troubleshooting

Common issues and solutions:

1. SAML Authentication Failures:
   - Verify metadata file is current
   - Check role ARN mappings
   - Validate group assignments

2. Access Denied Errors:
   - Verify resource tags match user attributes
   - Check role trust relationships
   - Validate ABAC policy conditions

3. Resource Creation Failures:
   - Verify AWS credentials
   - Check resource naming conflicts
   - Validate region settings

## Maintenance

Regular maintenance tasks:

1. Update Terraform providers:
```bash
terraform init -upgrade
```

2. Rotate SAML certificates:
   - Download new metadata from Okta
   - Update AWS SAML provider

3. Audit and clean up:
```bash
terraform plan
terraform apply
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License - See LICENSE file for details

## Support

For issues:
1. Check the troubleshooting guide
2. Open a GitHub issue
3. Contact your AWS/Okta support teams

## Version History

- 1.0.0: Initial release
  - Basic ABAC implementation
  - Okta SAML integration
  - Resource management
