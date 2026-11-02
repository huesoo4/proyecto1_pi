# Genera el inventario de Ansible (ansible/hosts) a partir de las IP del escenario.
# Se vuelve a generar en cada "tofu apply", así que no se edita a mano.
resource "local_file" "inventario" {
  filename        = "${path.module}/../ansible/hosts"
  file_permission = "0644"
  content = templatefile("${path.module}/inventario.tftpl", {
    ip_server_web = try(libvirt_domain.server-web.network_interface[0].addresses[0], "")
  })
}
