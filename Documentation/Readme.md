# Create VM in Azure with Terraform and Github Action

<br>

<details open>

<summary> <h2>I - Configuration on Azure</h2></summary>

<br>

First of all, you have to create a Service Principal. 

To do that, go on your Azure account and start the cloud shell :

![image0](/Documentation/Pictures/Cloud__Shell.png)

Then you have to run these commands :


```
az ad sp create-for-rbac --name TerraformFabryk --role Contributor --scopes /subscriptions/XXX --sdk auth
```

![image1](/Documentation/Pictures/1.png)

You have to keep the 4 first lines of the Json : **clientId**, **clientSecret**, **subscriptionId** and **tenantId**.

<br>

### • Create a stockage backend for the Terraform state
---
<br>

```
az group create -g ResourceGroupFabryk -l northeurope
```

![image2](/Documentation/Pictures/2.png)

<br>

### • Create a stockage account in the resource group
---
<br>

```
az storage account create -n terraformfabryk -g ResourceGroupFabryk -l northeurope --sku Standard_LRS
```

<br>

### • Create a container in the resource group
---
<br>

```
az storage container create -n terraformstatefabryk --account-name terraformfabryk
```
![image3](/Documentation/Pictures/4.PNG)

</details>

<details open>

<summary> <h2>II - Secrets</h2></summary>

<br>

You have to save the **clientId**, **clientSecret**, **subscriptionId** and **tenantId** as a secrets in github.

Go on Settings > Secrets and variables > Actions > New repository secret.

![image4](/Documentation/Pictures/5.png)

Once that is done, you should have 4 secrets :

![image5](/Documentation/Pictures/6.PNG)

</details>

<details open>

<summary> <h2>III - Terraform files</h2></summary>

<br>

You have to create a **providers.tf** file :

```
terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~>4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name = "ResourceGroupFabryk" ## Name of your Resource Group created in the step "Configuration on Azure"
    storage_account_name = "terraformfabryk" ## Name of your Storage account created in the step "Configuration on Azure"
    container_name = "terraformstatefabryk" ## Name of the container created in the step "Configuration on Azure"
    key = "terraform.tfstate"
 }
}
```
<br>

Then a main.tf file for the Virtual Machine :
```
resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "myVnet3"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "myNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = "VmFabrykTest"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "VmFabrykTest"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}
```

This is a default template find on the Microsoft Documentation. I've just modify some value such as the VM name, the virtual network name etc...
</details>

<details open>

<summary> <h2>IV - Github Action </h2></summary>
<br>

Now you have to create file in order to setting up github action : **.github/workflows/XXX.yaml** 

```
name: 'Deploy a VM in Azure with Terraform'
 
on:
  workflow_dispatch: # To run manually the action
    branches:
    - main
  pull_request:
 
jobs:
  terraform:
    name: 'Terraform'
    env:
      ARM_CLIENT_ID: ${{ secrets.FABRYK_AZURE_AD_CLIENT_ID }} ## Secret saved as the step "Secrets"
      ARM_CLIENT_SECRET: ${{ secrets.FABRYK_AZURE_AD_CLIENT_SECRET }} ## Secret saved as the step "Secrets"
      ARM_SUBSCRIPTION_ID: ${{ secrets.FABRYK_AZURE_SUBSCRIPTION_ID }} ## Secret saved as the step "Secrets"
      ARM_TENANT_ID: ${{ secrets.FABRYK_AZURE_AD_TENANT_ID }} ## Secret saved as the step "Secrets"
    runs-on: ubuntu-latest
    environment: production
 
    # Use the Bash shell regardless whether the GitHub Actions runner is ubuntu-latest, macos-latest, or windows-latest
    defaults:
      run:
        shell: bash
        working-directory: ./terraform ## Use the file in the terraform directory
 
    steps:
    # Checkout the repository to the GitHub Actions runner
    - name: Checkout
      uses: actions/checkout@v2

    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v1

    - name: List directory
      run: ls -a

    - name: Terraform Init
      run: terraform init

    - name: Terraform Plan
      run: terraform plan

    - name: Terraform Apply
      run: terraform apply -auto-approve

```
<br>

Now you juste have to click on the **Actions** button to see you Github Action :

![image8](/Documentation/Pictures/7.PNG).

<br>

Press the " Run workflow " button to see it in action :

![image9](/Documentation/Pictures/8.PNG)

<br>

And if you click on it iyou can see the different step of the action :

![image10](/Documentation/Pictures/9.PNG)

<br>

After few minutes :

![image11](/Documentation/Pictures/10.PNG)

<br>

You can see the VM on Azure :

![image12](/Documentation/Pictures/11.PNG)
