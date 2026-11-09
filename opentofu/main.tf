#################################
# SERVIDOR WEB 1
#################################

# Clon ligero sobre la imagen base: solo almacena los cambios diferenciales
resource "libvirt_volume" "server-web1-disk" {
  name             = "server-web1.qcow2"
  pool             = var.libvirt_pool_name
  base_volume_name = var.base_image_debian
  base_volume_pool = var.libvirt_pool_name
  format           = "qcow2"
}

# ISO cloud-init con la configuración inicial de la máquina
resource "libvirt_cloudinit_disk" "server-web1-cloudinit" {
  name           = "server-web1-cloudinit.iso"
  pool           = var.libvirt_pool_name
  user_data      = file("${path.module}/cloud-init/user-web1.yaml")
  network_config = file("${path.module}/cloud-init/network-web1-config.yaml")
}

# Definición del dominio (máquina virtual)
resource "libvirt_domain" "server-web1" {
  name   = "server-web1"
  memory = var.memoria
  vcpu   = var.vcpus

  # Red 1: NAT con DHCP (acceso exterior)
  network_interface {
    network_id     = libvirt_network.red_nat.id
    wait_for_lease = true
  }

  # Red 2: aislada sin DHCP (IP estática 10.0.50.3/24)
  network_interface {
    network_id = libvirt_network.red_datos.id
  }

  disk { volume_id = libvirt_volume.server-web1-disk.id }
  cloudinit = libvirt_cloudinit_disk.server-web1-cloudinit.id

  # Consola serie, las imágenes cloud la esperan (sin ella, algunas, como
  # Ubuntu, no terminan de arrancar) y nos permite entrar con "virsh console"
  # aunque falle la red
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}


#################################
# SERVIDOR WEB 2
#################################

# Clon ligero sobre la imagen base: solo almacena los cambios diferenciales
resource "libvirt_volume" "server-web2-disk" {
  name             = "server-web2.qcow2"
  pool             = var.libvirt_pool_name
  base_volume_name = var.base_image_debian
  base_volume_pool = var.libvirt_pool_name
  format           = "qcow2"
}

# ISO cloud-init con la configuración inicial de la máquina
resource "libvirt_cloudinit_disk" "server-web2-cloudinit" {
  name           = "server-web2-cloudinit.iso"
  pool           = var.libvirt_pool_name
  user_data      = file("${path.module}/cloud-init/user-web2.yaml")
  network_config = file("${path.module}/cloud-init/network-web2-config.yaml")
}

# Definición del dominio (máquina virtual)
resource "libvirt_domain" "server-web2" {
  name   = "server-web2"
  memory = var.memoria
  vcpu   = var.vcpus

  # Red 1: NAT con DHCP (acceso exterior)
  network_interface {
    network_id     = libvirt_network.red_nat.id
    wait_for_lease = true
  }

  # Red 2: aislada sin DHCP (IP estática 10.0.50.4/24)
  network_interface {
    network_id = libvirt_network.red_datos.id
  }

  disk { volume_id = libvirt_volume.server-web2-disk.id }
  cloudinit = libvirt_cloudinit_disk.server-web2-cloudinit.id

  # Consola serie, las imágenes cloud la esperan (sin ella, algunas, como
  # Ubuntu, no terminan de arrancar) y nos permite entrar con "virsh console"
  # aunque falle la red
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}


#################################
# SERVIDOR DB
#################################

# Clon ligero sobre la imagen base: solo almacena los cambios diferenciales
resource "libvirt_volume" "server-db-disk" {
  name             = "server-db.qcow2"
  pool             = var.libvirt_pool_name
  base_volume_name = var.base_image_ubuntu
  base_volume_pool = var.libvirt_pool_name
  format           = "qcow2"
}

# ISO cloud-init con la configuración inicial de la máquina
resource "libvirt_cloudinit_disk" "server-db-cloudinit" {
  name           = "server-db-cloudinit.iso"
  pool           = var.libvirt_pool_name
  user_data      = file("${path.module}/cloud-init/user-db.yaml")
  network_config = file("${path.module}/cloud-init/network-db-config.yaml")
}

# Definición del dominio (máquina virtual)
resource "libvirt_domain" "server-db" {
  name   = "server-db"
  memory = var.memoria
  vcpu   = var.vcpus

  # Red 1: NAT con DHCP (acceso exterior)
  network_interface {
    network_id     = libvirt_network.red_nat.id
    wait_for_lease = true
  }

  # Red 2: aislada sin DHCP (IP estática 10.0.50.2/24)
  network_interface {
    network_id = libvirt_network.red_datos.id
  }

  disk { volume_id = libvirt_volume.server-db-disk.id }
  cloudinit = libvirt_cloudinit_disk.server-db-cloudinit.id

  # Consola serie: las imágenes cloud la esperan (sin ella, algunas, como
  # Ubuntu, no terminan de arrancar) y permite entrar con "virsh console"
  # aunque falle la red
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

################################
# BALANCEADOR
###############################

# Contenedor LXC (Incus) con HAProxy: recibe las peticiones por la red NAT y
# las reparte entre los servidores web por la red de datos
resource "incus_instance" "balanceador" {
  name  = "balanceador"
  image = var.incus-cloud
  type  = "container"

  config = {
    "limits.cpu"           = var.vcpus
    "limits.memory"        = var.cmemoria
    "cloud-init.user-data" = file("${path.module}/cloud-init/user-balanceador.yaml")
    "cloud-init.network-config" = file("${path.module}/cloud-init/network-balanceador-config.yaml")

  }
  # Red 1: NAT con DHCP (acceso exterior)
  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype = "bridged"
      parent  = libvirt_network.red_nat.bridge
    }
  }

  # Red 2: aislada sin DHCP (IP estática 10.0.50.1/24)
  device {
    name = "eth1"
    type = "nic"
    properties = {
      nictype = "bridged"
      parent  = libvirt_network.red_datos.bridge
    }
  }

  wait_for {
    type = "ipv4"
    nic  = "eth0"
  }
}

# IP del balanceador en la red NAT (eth0), que es por donde entra Ansible. Se
# pregunta a la API de Incus. Lo usan el inventario y los outputs
data "external" "ip_balanceador" {
  depends_on = [incus_instance.balanceador]

  program = ["bash", "-c", <<-EOT
    incus query /1.0/instances/balanceador/state |
      jq '{ip: ([.network.eth0.addresses[] | select(.family=="inet" and .scope=="global")][0].address // "No disponible")}'
  EOT
  ]
}
