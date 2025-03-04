# Configure the Azure provider
provider "azurerm" {
  features {}
  subscription_id = "2c63fe1b-5386-424b-9198-a57bb4698643"
}

# Création d'un groupe de ressources
resource "azurerm_resource_group" "rg" {
  name     = "myResourceGroup"
  location = "francecentral"
}

# Crée un réseau virtuel
resource "azurerm_virtual_network" "vnet" {
  name                = "myVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}


# Création d'un sous-réseau
resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}


# Public IP for the master node
resource "azurerm_public_ip" "master_public_ip" {
  name                = "master-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

# Network interface for the master node
resource "azurerm_network_interface" "master_nic" {
  name                = "master-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.master_public_ip.id
  }
}

# Virtual machine for the master node
resource "azurerm_linux_virtual_machine" "master_vm" {
  name                = "machine-master"  # Nom du nœud master modifié
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.master_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("/home/ilyass/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

}

# Public IP for the worker node
resource "azurerm_public_ip" "worker_public_ip" {
  name                = "worker-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

# Network interface for the worker node
resource "azurerm_network_interface" "worker_nic" {
  name                = "worker-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.worker_public_ip.id
  }
}

# Virtual machine for the worker node
resource "azurerm_linux_virtual_machine" "worker_vm" {
  name                = "machine-worker"  # Nom du nœud worker modifié
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.worker_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("/home/ilyass/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

}

# Output pour les adresses IP publiques des machines virtuelles
output "public_ip_addresses" {
  value = {
    master = azurerm_public_ip.master_public_ip.ip_address
    worker = azurerm_public_ip.worker_public_ip.ip_address
  }
  description = "Les adresses IP publiques des machines virtuelles"
}

# Output pour les adresses IP privées des machines virtuelles
output "private_ip_addresses" {
  value = {
    master = azurerm_network_interface.master_nic.private_ip_address
    worker = azurerm_network_interface.worker_nic.private_ip_address
  }
  description = "Les adresses IP privées des machines virtuelles"
}
