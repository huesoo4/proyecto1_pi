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

# Memoria para servidores
variable "memoria" {
  description = "Cantidad de memoria RAM en MB"
  type = number
  default = 1024
}

# vCPUs para servidores y límite de CPU del contenedor balanceador
variable "vcpus" {
  description = "Número de vCPUs para cada servidor"
  type = number
  default = 2
}

# Imagen del contenedor LXC (balanceador)
variable "incus-cloud" {
  type = string
  description = "Nombre de la imagen para contenedor LXC Debian con cloud-init"
  default = "images:debian/13/cloud"
}

# Memoria para contenedores en el formato de Incus tiene que especificarse con unidad
variable "cmemoria" {
  description = "Límite de memoria RAM del contenedor (p. ej. 1024MiB)"
  type = string
  default = "1024MiB"
}

# Nombre de la aplicación. Solo se usa en el output "etc_hosts", tiene que
# coincidir con "dominio" de ansible/group_vars/servidores_web.yaml
variable "dominio" {
  type        = string
  description = "Nombre DNS de la aplicación"
  default     = "www.hueso.org"
}
