# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction

This is a project related to Udacity Azure DevOps nanodegree. It deploys a tagging policy, a Packer image, which, using Terraform, deploys a customizeable, scalable web server in Azure.

### Dependencies

1. Create an [Azure Account](https://portal.azure.com)
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Getting Started

1. Clone this repository

2. Set environment variables

3. Modify the packer file

4. Modify terraform variable files if needed

5. Create your infrastructure as code

### Instructions

The project is divided into three directories: **packer** for the image creation file, **terraform** for the Terraform files, and **policy** for the policy files. All the steps and the resulting output are shown in the Log.md file. The following steps are to be executed on the command line.

### 1. Authenticate into Azure
Using the Azure CLI, authenticate into your desired subscription: `az login`

### 2. Set environment variables
To get your azure variables:
`az ad sp create-for-rbac --query "{client_id: appId, client_secret: password, tenant_id: tenant}"`

Open on your terminal and add the following environment variables
- ARM_CLIENT_ID
- ARM_CLIENT_SECRET
- ARM_SUBSCRIPTION_ID
- ARM_TENANT_ID

These variables are used to connect to your subscription on Azure. Below are examples of adding enviroment variables to your terminal and os of choice.

#### Windows
Example: `setx ARM_CLIENT_ID '0000000-0000-0000-0000-000000000000'`

#### Mac OS
Example: `export ARM_CLIENT_ID='0000000-0000-0000-0000-000000000000'`

#### Linux
Example: `ARM_CLIENT_ID='0000000-0000-0000-0000-000000000000'`

### 3. Deploy a policy
This example policy will deny the creation of any resources with at least one tag

Create definition:

`az policy definition create --name tagging-policy --rules "tagging_policy.json" --display-name "deny-creation-of-untagged-resources" --description "This policy denies the creation of any resource if it does not have any tags" --mode All`

Create assignment:

`az policy assignment create --policy tagging-policy --name tagging-policy`

List the policy assignments to verify that the policy has been applied:

`az policy assignment list`

### 4. Create a Server Image
Create image:

`packer build server.json`

View images:

`az image list`

(When done) Delete images:

`az image delete -g <resource group> -n <name>`

### 5. Deploy infrastructure
(Optional) Customize vars.tf

Variables from vars.tf are called from main.tf, for example the variable prefix is called as:

`${var.prefix}`

In vars.tf, the description and value is assigned in the following manner:

    variable "prefix" 
    {
        description = "The prefix which should be used for all resources in the resource group specified"
        default = "udacity-nd82-project-1"
    }

Create infrastructure plan:

`terraform plan -out solution.plan`

Deploy the infrastructure plan:

`terraform apply "solution.plan"`

View infrastructure:

`terraform show`

(When done) Destroy infrastructure:

`terraform destroy`

### Output
See [here](./Log.md)
