```
terraform login
terraform init -upgrade
terraform fmt -recursive
```
### MFA未使用アカウントの場合は--no-sessionを付与しないとIAM関連作成のさいエラーが発生。
```
aws-vault exec xxxxxx -- terraform plan -var-file=envfile/env.tfvars
aws-vault exec xxxxxx -- terraform apply -var-file=envfile/env.tfvars
```