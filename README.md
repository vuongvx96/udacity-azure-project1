# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction

This is a project related to Udacity Azure DevOps nanodegree. It deploys a tagging policy, a Packer image, which, using Terraform, deploys a customizeable, scalable web server in Azure.

### Overview
This project will deploy a set number of virtual machines (default is 2) behind a load balancer, and set up all the other resources that need to be deployed for those virtual machines such as network security groups so the VM's are only accessible through the internal network, Virtual Networks, Subnets, Virtual Nics and more.

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

1. Deploy an Azure policy that ensures all resources are tagged
    - Create the Azure policy definition by running this command:

        `az policy definition create --name tagging-policy --rules "tagging_policy.json" --display-name "deny-creation-of-untagged-resources" --description "This policy denies the creation of any resource if it does not have any tags" --mode All`

    - Create the Azure policy assignment by running this command:

        `az policy assignment create --policy tagging-policy --name tagging-policy`
    - Verify policy effectiveness by creating resources

2. Create a Packer image deployable by Terraform
    - Create an image resource group named `Azuredevops` by: `az group create --location eastus --name Azuredevops`
    - Create a Service Principal for Terraform named `TerraformSP` by: `az ad sp create-for-rbac --role="Contributor" --name="TerraformSP"`, and such command outputs 5 values: `appId`, `displayName`, `name`, `password`, and `tenant`.
    - Export environment variables `ARM_CLIENT_ID` and `ARM_CLIENT_SECRET` that correspond to the above `appId` and `password`, respectively, as well as `ARM_SUBSCRIPTION_ID` which is the Azure Subscription ID.
    - Complete the Packer template file [server.json](./packer/server.json)
    - Create the image by: `packer build server.json` (if any user variables remain to be assigned, place `-var 'key=value'` between `packer build` and `server.json`)

3. Deploy Azure resources with Terraform
    - Complete terraform configuration files
    - Plan the Terraform deployment: `terraform plan -out solution.plan` ([vars.tf](./terraform/vars.tf) defines all Terraform user variables
    - Apply the Terraform deployment: `terraform apply "solution.plan"`

4. Destroy all Azure resources
    - Destroy resources built by Terraform: `terraform destroy`
    - Destroy image built by Packer: `az image delete -g Azuredevops -n myPackerImage`
### Output
See [here](./Log.md)
