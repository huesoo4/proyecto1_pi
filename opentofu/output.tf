# server-web
output "server-web" {
  value = {
    nombre = "server-web"
    ip1    = try(libvirt_domain.server-web.network_interface[0].addresses[0], "No disponible")
    ip2    = "10.0.50.1" # estática: está en cloud-init/network-config1.yaml
  }
}

# server-db
output "server-db" {
  value = {
    nombre = "server-db"
    ip1    = try(libvirt_domain.server-db.network_interface[0].addresses[0], "No disponible")
    ip2    = "10.0.50.2" # estática: está en cloud-init/network-config1.yaml
  }
}
