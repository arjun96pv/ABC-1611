resource "azurerm_resource_group" "rg1" {
  location = var.location
  name     = var.rg_name
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.rg_name
  address_space       = var.address_space
  location            = var.location

  depends_on = [azurerm_resource_group.rg1]
}


resource "azurerm_subnet" "sbnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_space

  depends_on = [azurerm_resource_group.rg1, azurerm_virtual_network.vnet]
}

resource "azurerm_ssh_public_key" "ssh" {
  name                = var.key
  resource_group_name = azurerm_resource_group.rg1.name
  location            = var.location
  public_key          = file("~/.ssh/id_rsa.pub")

  depends_on = [azurerm_resource_group.rg1]
}

resource "azurerm_public_ip" "pip" {
  name                = var.pip_name
  resource_group_name = azurerm_resource_group.rg1.name
  location            = var.location
  allocation_method   = "Static"

  depends_on = [azurerm_resource_group.rg1]
}

resource "azurerm_network_interface" "nic" {
  name                = var.nic_name
  resource_group_name = azurerm_resource_group.rg1.name
  location            = var.location
  ip_configuration {
    name                          = var.ip_name
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
    subnet_id                     = azurerm_subnet.sbnet.id
  }
  depends_on = [azurerm_resource_group.rg1]

}
resource "azurerm_linux_virtual_machine" "lvm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg1.name
  location            = var.location

  admin_username        = var.admin
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = var.size
  admin_ssh_key {
    public_key = file("~/.ssh/id_rsa.pub")
    username   = var.user
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  depends_on = [azurerm_resource_group.rg1]
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  security_rule {
    name                       = "sshport"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.rg1]

}

resource "azurerm_network_interface_security_group_association" "nsgasoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id

  depends_on = [azurerm_resource_group.rg1, azurerm_network_security_group.nsg]
}


resource "azurerm_virtual_network_peering" "example-2" {
  name                      = "peering2"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
}





