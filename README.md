# sftp-azure-terraform
How to create a sftp server on Azure using Terraform



## Repository structure

| Folder    | Description                                    |
|-----------|------------------------------------------------|
| docker    | JMeter custom image                            |
| docs      | Documentation and images                       |
| jmeter    | Contains JMX files used by JMeter agents       |
| pipelines | Docker and JMeter pipeline definitions         |
| scripts   | Scripts that support pipeline execution        |
| terraform | Terraform template for infrastructure creation |

## Prerequisites

* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
* [Azure DevOps CLI](https://docs.microsoft.com/en-us/azure/devops/cli/?view=azure-devops)
* [Service Principal](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest)
* [Azure Container Registry](https://azure.microsoft.com/en-us/services/container-registry/)
* Shell
* [jq](https://stedolan.github.io/jq/download/)


## Getting Started

### 1. 

### 4. Create Variable Groups

Get you service principal, your ACR credentials, and fill the following empty variables. Then, run this block on Bash:

```shell
CLIENT_ID=
CLIENT_SECRET=
TENANT_ID=
SUBSCRIPTION_ID=
ACR_NAME=
ACR_PASSWORD=
```

> Note: Make sure the `ACR_NAME` doesn't contain any capital letter, as it's an invalid ACR name convention.


Then run the following commands to create the variable groups `JMETER_AZURE_PRINCIPAL` and `JMETER_TERRAFORM_SETTINGS`:

```shell
PRIN_GROUP_ID=$(az pipelines variable-group create  --name JMETER_AZURE_PRINCIPAL --authorize \
                                                    --variables ARM_CLIENT_ID=$CLIENT_ID \
                                                                ARM_TENANT_ID=$TENANT_ID \
                                                                ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID \
                                                                | jq .id)

az pipelines variable-group variable create --group-id $PRIN_GROUP_ID --secret true \
                                            --name ARM_CLIENT_SECRET \
                                            --value $CLIENT_SECRET

SETT_GROUP_ID=$(az pipelines variable-group create  --name JMETER_TERRAFORM_SETTINGS --authorize \
                                                    --variables TF_VAR_JMETER_IMAGE_REGISTRY_NAME=$ACR_NAME \
                                                                TF_VAR_JMETER_IMAGE_REGISTRY_USERNAME=$ACR_NAME \
                                                                TF_VAR_JMETER_IMAGE_REGISTRY_SERVER=$ACR_NAME.azurecr.io \
                                                                TF_VAR_JMETER_DOCKER_IMAGE=$ACR_NAME.azurecr.io/jmeter \
                                                                | jq .id)

az pipelines variable-group variable create --group-id $SETT_GROUP_ID --secret true \
                                            --name TF_VAR_JMETER_IMAGE_REGISTRY_PASSWORD \
                                            --value $ACR_PASSWORD
```