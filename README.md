# typescript-lambda-fastify


## VSCode Remote-Containers

docker compose exec -u root terraform chown 1000:999 /home/terraform/.vscode-server


## Prepare Terraform backend

terraform init -reconfigure -backend-config=dev-backend.tfvars
terraform plan -var-file dev.tfvars -out tfplan
terraform apply tfplan

### If Github OIDC Provider already exists

terraform import aws_iam_openid_connect_provider.github_actions arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com
