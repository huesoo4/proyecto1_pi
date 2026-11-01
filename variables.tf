# Pool de almacenamiento donde se crean los volúmenes (disco y cloud-init)
variable "libvirt_pool_name" {
  type        = string
  description = "Nombre del pool de almacenamiento libvirt."
  default     = "default"
}

# Imagen base Debian 13 para el servidor web
variable "base_image_debian" {
  type        = string
  description = "Nombre de la imagen base Debian 13 en el pool."
  default     = "debian13-base1.qcow2"
}

# Imagen base Ubuntu 26.04 para el servidor de base de datos
variable "base_image_ubuntu" {
  type        = string
  description = "Nombre de la imagen base Ubuntu 26.04 en el pool."
  default     = "ubuntu2604-base.qcow2"
}
