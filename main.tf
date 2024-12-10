terraform {
  required_version = ">= 1.6.6"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. create resource
resource "azurerm_resource_group" "main" {
  name     = "devopstest-rg"
  location = var.location
}

# 2. Create a virtual network and subnet
resource "azurerm_virtual_network" "main" {
  name                = "devopstest-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 3. create public IP
resource "azurerm_public_ip" "main" {
  name                = "devopstest-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
}

# 4. Create an NSG and restrict SSH access sources
resource "azurerm_network_security_group" "main" {
  name                = "devopstest-nsg"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_cidr
    destination_address_prefix = "*"
  }
}

# 5. Create a network interface and associate it with the NSG and subnet
resource "azurerm_network_interface" "main" {
  name                = "devopstest-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# 6. Select the appropriate AlmaLinux/Rocky Linux 9.x image
# AlmaLinux 9 is used as an example here (we need to find the image in Azure)
data "azurerm_image" "almalinux" {
  name                = "almalinux-9-latest"
  resource_group_name = "YourImageResourceGroup" # 请根据实际情况调整
}

# 7. Create a VM and attach a disk
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "devopstest"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.main.id
  ]

  source_image_id = data.azurerm_image.almalinux.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  data_disk {
    lun                  = 0
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 15
    create_option        = "Empty"
  }

  # Pass cloud-init 
  custom_data = filebase64("cloud-init.yaml")

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }
}
