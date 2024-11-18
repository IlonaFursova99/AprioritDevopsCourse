# Define provider
provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "example_rg" {
  name     = "example-resource-group"
  location = "Canada Central"
}


# Virtual Network
resource "azurerm_virtual_network" "example_vnet" {
  name                = "example-vnet"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
  address_space       = ["10.0.0.0/16"]
}

# 2 Subnets
resource "azurerm_subnet" "example_subnet" {
  count               = 2
  name                = "example-subnet-${count.index}"
  resource_group_name = azurerm_resource_group.example_rg.name
  virtual_network_name = azurerm_virtual_network.example_vnet.name
  address_prefixes    = ["10.0.${count.index}.0/24"]
}

# 2 network interfaces
resource "azurerm_network_interface" "example_nic" {
  count               = 2
  name                = "example-nic-${count.index}"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name

  ip_configuration {
    name                          = "example-ipconfig-${count.index}"
    subnet_id                     = azurerm_subnet.example_subnet[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
}


# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "example-nsg"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name

#HTTP Port Opened 
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

#SSH 
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

#Restricted to Apriorit IPs
  security_rule {
    name                       = "RestrictToAprioritIPs"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefixes    = ["85.198.144.37", "10.95.0.116"] #Prituln server address + my local IP
    destination_address_prefix = "*"
  }

}

# Subnet Network Security Group Association
resource "azurerm_subnet_network_security_group_association" "example" {
  count                     = length(azurerm_subnet.example_subnet)
  subnet_id                 = azurerm_subnet.example_subnet[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Virtual Machines 1,2

resource "azurerm_linux_virtual_machine" "vm" {
  count                 = 2
  name                  = "example-vm-${count.index}"
  resource_group_name = azurerm_resource_group.example_rg.name
  location            = azurerm_resource_group.example_rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.example_nic[count.index].id]

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
  #Path to public key
  admin_ssh_key {
    username   = "azureuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDrG7Pmk7ddQjCbcEOKJWNWKBdMhOcrp7T1oUohqrcyjOyWsLtK7+Cs5mpZtLlI7YmZXCZ0v6HbYcSO8hxfF2EITqr6/laEbfCfIPW+RUxG19szzUgoEtiupITyzxGSXBtIRbSYHpKJT1di3tCcOOgL+ecoafUbsySGXuHXHhpHU29mNHiE6GVtC/tRNfQhQ83rfIR6v+lYs+R4HiYpk89Fff7WtWUubOj8tmEhadho3fBw7+yBkswqeYV9fkXqKsFp5kX57/qI4ytt29r2M8VFz7g+PjWSOeSWqf1H1E5QsxDSyPYHlCHyIywq1adlEVrWXZUEH+eY6CTBGygmPVQD"  
  }
}
