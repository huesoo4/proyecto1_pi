# Genera el inventario de Ansible (ansible/hosts) a partir de las IP del escenario.
# Se vuelve a generar en cada "tofu apply", así que no se edita a mano.
resource "local_file" "inventario" {
  filename        = "${path.module}/../ansible/hosts"
  file_permission = "0644"
  content = templatefile("${path.module}/inventario.tftpl", {
    # Red de gestión (por donde entra Ansible)
    ip_server_web1 = try(libvirt_domain.server-web1.network_interface[0].addresses[0], "")
    ip_server_web2 = try(libvirt_domain.server-web2.network_interface[0].addresses[0], "")
    ip_server_db   = try(libvirt_domain.server-db.network_interface[0].addresses[0], "")
    ip_balanceador = data.external.ip_balanceador.result.ip
  })
}
