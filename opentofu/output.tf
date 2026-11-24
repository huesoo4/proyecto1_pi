# server-web1
output "server-web1" {
  value = {
    nombre = "server-web1"
    ip    = "10.0.50.3" # estática: está en cloud-init/network-web1-config.yaml
  }
}

# server-web2
output "server-web2" {
  value = {
    nombre = "server-web2"
    ip    = "10.0.50.4" # estática: está en cloud-init/network-web2-config.yaml
  }
}

# server-db
output "server-db" {
  value = {
    nombre = "server-db"
    ip    = "10.0.50.2" # estática: está en cloud-init/network-db-config.yaml
  }
}

# server-nextcloud1
output "server-nextcloud1" {
  value = {
    nombre = "server-nextcloud1"
    ip    = "10.0.50.5" # estática: está en cloud-init/network-nextcloud1-config.yaml
  }
}

# server-nextcloud2
output "server-nextcloud2" {
  value = {
    nombre = "server-nextcloud2"
    ip    = "10.0.50.6" # estática: está en cloud-init/network-nextcloud2-config.yaml
  }
}

# server-db-nextcloud
output "server-db-nextcloud" {
  value = {
    nombre = "server-db-nextcloud"
    ip    = "10.0.50.7" # estática: está en cloud-init/network-db-nextcloud-config.yaml
  }
}

# balanceador
output "balanceador" {
  value = {
    nombre = incus_instance.balanceador.name
    ip1    = data.external.ip_balanceador.result.ip
    ip2    = "10.0.50.1" # estática: está en cloud-init/network-balanceador-config.yaml
  }
}

# Línea para /etc/hosts del anfitrión: los nombres de las aplicaciones apuntan
# al balanceador, no a un servidor concreto
output "etc_hosts" {
  value = "${data.external.ip_balanceador.result.ip} ${var.dominio} ${var.dominio_nextcloud}"
}
