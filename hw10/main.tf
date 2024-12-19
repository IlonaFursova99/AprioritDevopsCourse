# Define provider
provider "azurerm" {
  features {}
  subscription_id = "9502ad3f-ec46-4984-afcc-a29df4b70a7d"
}

# Resource Group
resource "azurerm_resource_group" "example_rg" {
  name     = "ilona-resource-group"
  location = "Canada Central"
}

# Virtual Network
resource "azurerm_virtual_network" "example_vnet" {
  name                = "example-vnet"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "example_subnet" {
  name                = "example-subnet"
  resource_group_name = azurerm_resource_group.example_rg.name
  virtual_network_name = azurerm_virtual_network.example_vnet.name
  address_prefixes    = ["10.0.0.0/24"]
}

# Network Interface
resource "azurerm_network_interface" "example_nic" {
  name                = "example-nic"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name

  ip_configuration {
    name                          = "example-ipconfig"
    subnet_id                     = azurerm_subnet.example_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Public IP
resource "azurerm_public_ip" "example_public_ip" {
  name                         = "example-public-ip"
  location                     = azurerm_resource_group.example_rg.location
  resource_group_name          = azurerm_resource_group.example_rg.name
  allocation_method            = "Dynamic"
  domain_name_label            = "examplepublicip"
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "example-nsg"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name

  # HTTP Port Opened 
  security_rule {
    name                       = "WEB"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # SSH Port
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

# VM
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "example-vm"
  resource_group_name   = azurerm_resource_group.example_rg.name
  location              = azurerm_resource_group.example_rg.location
  size                  = "Standard_B1s"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.example_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # Path to public key
  admin_ssh_key {
    username   = "azureuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDrG7Pmk7ddQjCbcEOKJWNWKBdMhOcrp7T1oUohqrcyjOyWsLtK7+Cs5mpZtLlI7YmZXCZ0v6HbYcSO8hxfF2EITqr6/laEbfCfIPW+RUxG19szzUgoEtiupITyzxGSXBtIRbSYHpKJT1di3tCcOOgL+ecoafUbsySGXuHXHhpHU29mNHiE6GVtC/tRNfQhQ83rfIR6v+lYs+R4HiYpk89Fff7WtWUubOj8tmEhadho3fBw7+yBkswqeYV9fkXqKsFp5kX57/qI4ytt29r2M8VFz7g+PjWSOeSWqf1H1E5QsxDSyPYHlCHyIywq1adlEVrWXZUEH+eY6CTBGygmPVQD"
  }

  # Public IP association
  depends_on = [azurerm_public_ip.example_public_ip]
}

# Output public IP
output "vm_public_ip" {
  value = azurerm_public_ip.example_public_ip.ip_address
}
