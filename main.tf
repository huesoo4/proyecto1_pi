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

