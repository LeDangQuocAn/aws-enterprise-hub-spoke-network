# aws-enterprise-hub-spoke-network

Sprint 1 for the university AWS hub-and-spoke design focuses on Terraform Cloud-backed infrastructure delivery and the core Transit Gateway.

## Terraform Cloud backend

Update the `terraform` block in [versions.tf](versions.tf) with your Terraform Cloud organization and workspace name before running the first init.

### CLI bootstrap

```bash
terraform login
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
```

If you want to initialize against a specific workspace after the first login, make sure the workspace already exists in Terraform Cloud and matches the name configured in [versions.tf](versions.tf).

### Terraform Cloud workspace variables

Inject AWS credentials into the Terraform Cloud workspace as environment variables:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN` if you are using temporary credentials

Use the Terraform Cloud UI or the Terraform Cloud API to create these as sensitive environment variables. Do not commit them to the repository, and do not place them in `.tfvars` files.

### GitHub Actions secrets

For the CI/CD workflow, store the following in GitHub repository secrets:

- `TF_API_TOKEN`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN` if needed

The workflow uses `TF_API_TOKEN` to authenticate directly with Terraform Cloud and passes AWS credentials to the AWS provider at runtime.

## Transit Gateway scope

Sprint 1 provisions only the hub Transit Gateway with strict routing defaults:

- `auto_accept_shared_attachments = "enable"`
- `default_route_table_association = "disable"`
- `default_route_table_propagation = "disable"`

That keeps attachment and route propagation control explicit for later spoke onboarding.
