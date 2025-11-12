# This script is meant to solve dns issue when you can't access the private cluster from the bastion host.

# Get the Resource ID of the node you want to SSH into (from the portal)
read -p "Enter the Resource ID of the node to connect to: " VM_NODE_ID

# Get Bastion's name from Terraform
BASTION_NAME=$(terraform output bastion_host_name)
RG_NAME=$(terraform output resource_group_name)

az network bastion ssh --name $BASTION_NAME --resource-group $RG_NAME --target-resource-id $VM_NODE_ID --auth-type ssh-key --ssh-key "~/.ssh/id_rsa"