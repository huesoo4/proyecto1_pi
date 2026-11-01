# Pool de almacenamiento donde se crean los volúmenes (disco y cloud-init)
variable "libvirt_pool_name" {
  type        = string
  description = "Nombre del pool de almacenamiento libvirt."
  default     = "default"
}
