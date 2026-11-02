# Red NAT con DHCP: acceso a las máquinas desde el equipo anfitrión y salida a internet
resource "libvirt_network" "red_nat" {
  name      = "red_nat"
  mode      = "nat"
  domain    = "p1.local"
  addresses = ["192.168.160.0/24"]
  dhcp { enabled = true }
  dns { enabled = true }
  autostart = true
}

# Red de datos muy aislada (mode=none): solo la usan web y bd, con IP estáticas
resource "libvirt_network" "red_datos" {
  name      = "red_datos"
  mode      = "none"
  autostart = true
}
