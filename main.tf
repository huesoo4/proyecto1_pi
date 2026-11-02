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
