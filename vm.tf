terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    spacelift = {
      source = "spacelift-io/spacelift"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

# 🔹 Create a Resource Group
resource "azurerm_resource_group" "vm_rg" {
  name     = "spacelift-vm-rg"
  location = "East US"
}

# 🔹 Create a Virtual Network
resource "azurerm_virtual_network" "vm_vnet" {
  name                = "spacelift-vnet"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name
  address_space       = ["10.0.0.0/16"]
}

# 🔹 Create a Subnet
resource "azurerm_subnet" "vm_subnet" {
  name                 = "spacelift-subnet"
  resource_group_name  = azurerm_resource_group.vm_rg.name
  virtual_network_name = azurerm_virtual_network.vm_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 🔹 Create a Public IP
resource "azurerm_public_ip" "vm_ip" {
  name                = "spacelift-vm-ip"
  resource_group_name = azurerm_resource_group.vm_rg.name
  location            = azurerm_resource_group.vm_rg.location
  allocation_method   = "Static"
}

# 🔹 Create a Network Interface
resource "azurerm_network_interface" "vm_nic" {
  name                = "spacelift-vm-nic"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name

  ip_configuration {
    name                          = "vm-nic-config"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_ip.id
  }
}

# 🔹 Create a Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "spacelift-vm"
  resource_group_name = azurerm_resource_group.vm_rg.name
  location            = azurerm_resource_group.vm_rg.location
  size                = "Standard_B1s"  # Adjust VM size as needed
  admin_username      = "adminuser"
  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")  # Ensure your SSH key is available
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }
}

# 🔹 Spacelift Stack for VM Deployment
resource "spacelift_stack" "vm_stack" {
  name       = "azure-vm-stack"
  repository = "ANawle/Azure-Spacelift"  # Replace with your actual repo
  branch     = "main"

  labels = ["azure", "terraform", "vm"]
}
