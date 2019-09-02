Terraform configuration for setting up new AWS accounts for use in TeamCity agents.

To use, first login using maws to every account you see in `main.tf`:

```
maws login "Team 01"
eval $(maws login "toolsinfra")
```

Then you can run terraform:

```
terraform init
terraform apply
```
