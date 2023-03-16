# RXMG Infrastructure

## _Provisioned By Terraform_

This project provisions the RXPlatform staging and production clusters with the appropriate resources, including SSL, Ingress, Deployments, Services and more (with the exception of InfluxDB and the secrets in Google Secret Manager, both of which must currently be created manually). This project also sets up the pipeline cluster in GKE, which includes the GitLab pipeline runner. This project also includes the infrastructure for the misc Kubernetes cluster and projects. It also sets up all dev permissions for GCP. It also sets up the domain silos. There is also a general configuration shared between environments that is provisioned.

> **_NOTE:_** All new infrastructure should be added here whenever possible.

## Security Considerations

Currently, any sensitive data used in these configuration files is stored in LastPass and must be manually provided when running Terraform. This can be done either directly through the terraform command, or by creating a secrets.tfvars file and passing that file into the terraform command (by appending --var-file secrets.tfvars). Do **NOT** add secrets directly to configuration files or to source control.

> **_NOTE:_** Each main configuration file may include multiple other configuration files. If either the main configuration file or its subconfiguration files has sensitive data, then that block of configuration files as a whole is considered to have sensitive data and must use GCS to store the state file for that block of configuration files. This is the default for any configuration, but it needs to be understood that the Terraform state GCS bucket contains sensitive data and only a select few should have access to it.

## Setup

Navigate to the root directory of the project and run the following command to install Terraform if you haven't already.

```sh
brew install terraform
```

If you haven't done so already, initialize your default gcloud profile.
```sh
gcloud init
```

You must then authenticate with GCP.

```sh
gcloud auth application-default login
```

More information about authenticating with GCP outside of your workstation can be found [here](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference).

> **_NOTE:_** Always verify that you are in the correct directory before running any terraform command.
To setup the terraform infrastructure environment.

To setup the base terraform environment for use with remote backends for all other environments.

```sh
cd terraform
terraform init
terraform apply
```

To setup the dev environment.

```sh
cd dev
terraform init
terraform apply
```

To setup the RXPlatform dynamic environment (for hosting merge request micro environments).

```sh
cd rxplatform/development
terraform init
terraform apply
```

To setup the RXPlatform QA environment.

```sh
cd rxplatform/qa
terraform init
terraform apply
```

To setup the RXPlatform staging environment.

```sh
cd rxplatform/staging
terraform init
terraform apply
```

To setup the RXPlatform production environment ...

```sh
cd rxplatform/prod
terraform init
terraform apply
```

To setup the misc environment ...

```sh
cd misc
terraform init
terraform apply
```

To setup the pipelines environment ...

```sh
cd pipelines
terraform init
terraform apply
```

To setup the general shared environment ...

```sh
cd general
terraform init
terraform apply
```

To setup the consumer mail environment.
```sh
cd mail
terraform init
terraform apply
```

Terraform will ask for confirmation of the plan. After approving, wait for Terraform to finish provisioning the resources.