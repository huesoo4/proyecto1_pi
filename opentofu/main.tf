#################################
# SERVIDOR WEB
#################################

# Clon ligero sobre la imagen base: solo almacena los cambios diferenciales
resource "libvirt_volume" "server-web-disk" {
  name             = "server-web.qcow2"
  pool             = var.libvirt_pool_name
  base_volume_name = var.base_image_debian
  base_volume_pool = var.libvirt_pool_name
  format           = "qcow2"
}

# ISO cloud-init con la configuración inicial de la máquina
resource "libvirt_cloudinit_disk" "server-web-cloudinit" {
  name           = "server-web-cloudinit.iso"
  pool           = var.libvirt_pool_name
  user_data      = file("${path.module}/cloud-init/user-web.yaml")
  network_config = file("${path.module}/cloud-init/network-web-config.yaml")
}

# Definición del dominio (máquina virtual)
resource "libvirt_domain" "server-web" {
  name   = "server-web"
  memory = 1024
  vcpu   = 2

  # Red 1: NAT con DHCP (acceso exterior)
  network_interface {
    network_id     = libvirt_network.red_nat.id
    wait_for_lease = true
  }

  # Red 2: aislada sin DHCP (IP estática 10.0.50.1/24)
  network_interface {
    network_id = libvirt_network.red_datos.id
  }

  disk { volume_id = libvirt_volume.server-web-disk.id }
  cloudinit = libvirt_cloudinit_disk.server-web-cloudinit.id

  # Consola serie: las imágenes cloud la esperan (sin ella, algunas, como
  # Ubuntu, no terminan de arrancar) y permite entrar con "virsh console"
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
  memory = 1024
  vcpu   = 2

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
