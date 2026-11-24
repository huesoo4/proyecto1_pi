# Genera el inventario de Ansible (ansible/hosts) a partir de las IP del escenario.
# Se vuelve a generar en cada "tofu apply", así que no se edita a mano.
resource "local_file" "inventario" {
  filename        = "${path.module}/../ansible/hosts"
  file_permission = "0644"
  content = templatefile("${path.module}/inventario.tftpl", {
    # Red de gestión (por donde entra Ansible)
    ip_server_web1 = "10.0.50.3"
    ip_server_web2 = "10.0.50.4"
    ip_server_db   = "10.0.50.2"

    ip_server_nextcloud1   = "10.0.50.5"
    ip_server_nextcloud2   = "10.0.50.6"
    ip_server_db_nextcloud = "10.0.50.7"

    ip_balanceador = data.external.ip_balanceador.result.ip
  })
}
