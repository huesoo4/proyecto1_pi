terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
    # Para escribir ficheros en el equipo (el inventario de Ansible)
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    incus = {
      source  = "lxc/incus"
      version = "~> 1.1.1"
    }
    external = { 
      source = "hashicorp/external" 
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

provider "incus" {}
