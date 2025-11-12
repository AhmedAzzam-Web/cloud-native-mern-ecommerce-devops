# Get Bastion's name from Terraform
BASTION_NAME=$(terraform output bastion_host_name)
RG_NAME=$(terraform output resource_group_name)

# in the new shell, kubectl commands will be securely tunneled to private cluster.
az aks bastion --resource-group $RG_NAME --name $BASTION_NAME