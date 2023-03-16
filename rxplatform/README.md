# RXPlatform Infrastructure
This directory holds the core modules for the RXPlatform infrastructure. 

## Environment Types
We use two different environment types, live (static) environments and dynamic environments. There are some differences between them, but they function similarly.

### Updating Environment Variables
For all environments in the RXPlatform infrastructure, GCP secrets are used to hold the .env files (one for each app) for the environment. The Terraform config pulls down the corrresponding GCP secret, creates/updates a Kubernetes secret, then injects the contents of that Kubernetes secret directly into the pods of the app's deployment as a read-only .env file in the working directory. To update these, the GCP secret must be updated, after which the Terraform module for the environment must be rerun to see those changes.

> **_WARNING:_** If you run Terraform, it will update the Kubernetes secrets, but will **not** update existing deployments to pull the new .env file. It is necessary to either wait until the pods restart themselves or force a restart either through an updated deployment (as in the case of the pipeline deploys), or with a rollout restart of the deployment.

### Live Environments
We currently have 3 different live environments, each under their own subdirectory: QA, staging, and production. There is also a shared modules subdirectory, which each environment uses heavily. Each of these environments has a separate state file, and each must be updated separately in their corresponding directories with a Terraform command.

> **_WARNING:_** Be careful when updating anything in a **modules** directory, as that may have changes across **all** environments. 

### Dynamic Environments
Under the development directory is the module, which sets up the base infrastructure for the dynamic (also referred to as micro) environments to be set up. This is run statically, similarly to the live environments. Under that development directory is the dynamic directory, which is used by the merge request pipelines to spin up a micro environment.

##### Environment Variables
The dynamic environments have one other way of setting environment variables, which is by directly injecting them into the environment as environment variables, rather than as a simple .env file. This is done to allow overriding of certain variables that may differ between environments, such as _APP\_ENV_ (which corresponds to the branch/ticket name).

##### OpenVPN
The dynamic environments put everything (with a few exceptions), behind the VPN. This means that routes and VPN DNS records are created dynamically in these modules. The OpenVPN API is currently in beta and has no official Terraform provider, so we have created one [here](https://github.com/RXMG/terraform-provider-openvpncloud). Any bugs in the provider (or workarounds for the beta API) should be patched there and republished to the public Terraform registry.

> **_IMPORTANT:_** DO NOT PUT ANY SENSITIVE DATA INTO THIS PROVIDER, AS IT IS PUBLIC!

##### Common Issues
There are several known issues that may occur when running the dynamic environment modules.

###### Script Fails With A Kubernetes Job In Failed State
Most likely, the job timed out. Rerunning the script will likely fix the issue. Alternatively, if the job starts taking longer than usual consistently, you can increase job timeouts by setting the timeout in the job details in `rxplatform/development/dynamic/applications/main.tf`

###### Script Fails With Error Unlocking Workspace
This happens when another script is also running on the same module. In most cases, however, it is because someone force killed the script while it was running and the script didn't have the chance to unlock the workspace. To solve it, verify that no one else is running the script, then either delete the .tflock file in the GCP bucket `rxmg-infrastructure-terraform-state` under the corresponding directory, or use `terraform force-unlock $LOCK_ID` to delete it through the CLI (the $LOCK_ID can be found in the output of the error). After removing the lock file, the module is free to be used.


## Modifying Parameters
In some cases, it might be necessary to modify the parameters of some of the modules. After any modification, it's necessary to rerun Terraform to apply the changes.

### Modifying Autoscaling Parameters
There are two kinds of autoscaling currently used by RXPlatform: node autoscaling and horizontal pod autoscaling (HPA).

#### Node Autoscaling
This autoscaling controls the min/max number of nodes the cluster may have. It is modified in the base module for each environment (ex. `rxplatform/production/main.tf`), through the **min_nodes** and **max_nodes** parameters in the locals block.

#### HPA
This autoscaling controls the min/max number of pods a deployment may have. It is modified in the module for each app (ex. `rxplatform/modules/applications/backend/main.tf`), through the **min_replicas** and **max_replicas** parameters in each deployment block for each type of app (such as web, queue, scheduler). These values are overridden in the dynamic environments for cost reasons and can be changed for those environments in the same way in the dynamic applications module: `rxplatform/development/dynamic/applications/main.tf`.