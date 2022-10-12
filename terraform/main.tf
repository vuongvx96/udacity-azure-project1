provider "azurerm" {
  features {}
}

# Create the resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group
  location = var.location

  tags = {
    project = var.prefix
  }
}

# create a virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    project = var.prefix
  }
}

# Create the subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create the network security group
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-sg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    project = var.prefix
  }

  security_rule {
    name                       = "AllowVMAccessOnSubnet"
    description                = "Allow access to other VMs on the subnet"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    access                     = "Allow"
    priority                   = "2000"
    direction                  = "Inbound"
  }

  security_rule {
    name                       = "DenyDirectAcessFromInternet"
    description                = "Denies direct access from the internet"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
    access                     = "Deny"
    priority                   = "1000"
    direction                  = "Inbound"
  }
}

# Create network interface
resource "azurerm_network_interface" "main" {
  count               = var.num_of_vms
  name                = "${var.prefix}-nic-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    project = var.prefix
  }
}

# Create public IP
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-public-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"

  tags = {
    project = var.prefix
  }
}

# Create load balancer
resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    project = var.prefix
  }

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

# The load balancer will use this backend pool
resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "${var.prefix}-lb-backend-pool"
}


# We associate the LB with the backend address pool
resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = var.num_of_vms
  network_interface_id    = azurerm_network_interface.main[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_lb_probe" "main" {
  name            = "${var.prefix}-web-running-probe"
  loadbalancer_id = azurerm_lb.main.id
  port            = 8080
}

resource "azurerm_lb_rule" "main" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "${var.prefix}-LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 8080
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.main.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
}

# Create virtual machine availability set
resource "azurerm_availability_set" "main" {
  name                = "${var.prefix}-aset"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    project = var.prefix
  }
}

data "azurerm_image" "packer_image" {
  name                = var.packer_image
  resource_group_name = var.packer_image_rg
}

# Create the virtual machines
resource "azurerm_linux_virtual_machine" "main" {
  count                           = var.num_of_vms
  name                            = "${var.prefix}-vm-${count.index}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_B1s"
  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.main[count.index].id]
  availability_set_id             = azurerm_availability_set.main.id

  source_image_id = data.azurerm_image.packer_image.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    project = var.prefix
  }
}

# A virtual disk floating around
resource "azurerm_managed_disk" "disk" {
  count                = var.num_of_vms
  name                 = "${var.prefix}-disk-${count.index}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1

  tags = {
    project = var.prefix
  }
}

# Mount the disk into the VM
resource "azurerm_virtual_machine_data_disk_attachment" "mount_disk" {
  count              = var.num_of_vms
  managed_disk_id    = azurerm_managed_disk.disk[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.main[count.index].id
  lun                = 10 * count.index
  caching            = "ReadWrite"
}
