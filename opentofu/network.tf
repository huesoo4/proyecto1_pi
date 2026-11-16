# Red NAT con DHCP: solo se conecta el balanceador. Por ella se accede desde el
# equipo anfitrión y sale a internet todo el escenario
resource "libvirt_network" "red_nat" {
  name      = "red_nat"
  mode      = "nat"
  domain    = "p1.local"
  addresses = ["192.168.160.0/24"]
  dhcp { enabled = true }
  dns { enabled = true }
  autostart = true
}

# Red de datos muy aislada (mode=none), con IP estáticas. Es la única red de las VMs:
# su puerta de enlace es el balanceador 10.0.50.1
resource "libvirt_network" "red_datos" {
  name      = "red_datos"
  mode      = "none"
  autostart = true
}
