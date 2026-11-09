# server-web1
output "server-web1" {
  value = {
    nombre = "server-web1"
    ip1    = try(libvirt_domain.server-web1.network_interface[0].addresses[0], "No disponible")
    ip2    = "10.0.50.3" # estática: está en cloud-init/network-web1-config.yaml
  }
}

# server-web2
output "server-web2" {
  value = {
    nombre = "server-web2"
    ip1    = try(libvirt_domain.server-web2.network_interface[0].addresses[0], "No disponible")
    ip2    = "10.0.50.4" # estática: está en cloud-init/network-web2-config.yaml
  }
}

# server-db
output "server-db" {
  value = {
    nombre = "server-db"
    ip1    = try(libvirt_domain.server-db.network_interface[0].addresses[0], "No disponible")
    ip2    = "10.0.50.2" # estática: está en cloud-init/network-db-config.yaml
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

# Línea para /etc/hosts del anfitrión: el nombre de la aplicación apunta al
# balanceador, no a un servidor web concreto
output "etc_hosts" {
  value = "${data.external.ip_balanceador.result.ip} ${var.dominio}"
}
