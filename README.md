# Proyecto 1: Infraestructura como código

Escenario creado con **OpenTofu** (libvirt + Incus) y configurado con **Ansible** para poner en producción la aplicación [guestbook_php](https://github.com/josedom24/guestbook_php) (PHP + MariaDB).

- `opentofu/`: el escenario (redes, máquinas, cloud-init y el inventario de Ansible).
- `ansible/`: la configuración (`site.yaml` con los roles `commons`, `router`, `cortafuegos`, `bd`, `web` y `balanceador`).

## Escenario

```
                         Equipo anfitrión
                                │
               red_nat  192.168.160.0/24  (NAT + DHCP)
                                │
                           eth0 (DHCP)
                       ┌─────────────────┐
                       │   balanceador   │
                       │   LXC (Incus)   │
                       │ HAProxy + router│
                       └─────────────────┘
                         eth1 10.0.50.1
                                │
         red_datos  10.0.50.0/24  (muy aislada, IP estáticas)
          │                     │                     │
    ens3 10.0.50.3        ens3 10.0.50.4        ens3 10.0.50.2
  ┌─────────────┐      ┌─────────────┐      ┌──────────────┐
  │ server-web1 │      │ server-web2 │      │  server-db   │
  │  Debian 13  │      │  Debian 13  │      │ Ubuntu 26.04 │
  │ Apache+PHP  │      │ Apache+PHP  │      │   MariaDB    │
  └─────────────┘      └─────────────┘      └──────────────┘
```

| Máquina | Tipo | Sistema | Red NAT (`red_nat`) | Red de datos (`red_datos`) | Grupo de Ansible |
|---|---|---|---|---|---|
| `balanceador` | Contenedor LXC (Incus) | Debian 13 | DHCP | 10.0.50.1/24 | `balanceadores` |
| `server-web1` | VM (libvirt) | Debian 13 | — | 10.0.50.3/24 | `servidores_web` |
| `server-web2` | VM (libvirt) | Debian 13 | — | 10.0.50.4/24 | `servidores_web` |
| `server-db` | VM (libvirt) | Ubuntu 26.04 | — | 10.0.50.2/24 | `servidores_bd` |

- Las VM son clones ligeros de las imágenes base `debian13-base1.qcow2` y `ubuntu2604-base.qcow2` del pool `default`. El balanceador es un contenedor Incus (`images:debian/13/cloud`) conectado a los dos bridges de libvirt.
- Los servidores **solo** están en la red de datos, que es `mode = "none"`: el anfitrión no tiene IP en ella. Su puerta de enlace es el balanceador, que hace de **router** (NAT con iptables) y les da salida a internet. Usan como DNS el de libvirt (`192.168.160.1`), al que llegan a través del balanceador.
- Ansible llega a los servidores saltando por SSH a través del balanceador (`ProxyCommand` en el inventario).
- HAProxy recibe las peticiones por la red NAT y las reparte (`roundrobin`) entre los dos servidores web por la red de datos. Con una cookie (`SERVIDOR`) cada navegador se queda en el mismo servidor web, porque la aplicación guarda el token CSRF en la sesión de PHP, que es local de cada servidor.
- Los dos servidores web comparten la misma base de datos. MariaDB solo escucha en la red de datos, y el usuario de la aplicación solo puede conectarse desde las IP de los servidores web.
- Cada servidor tiene un **cortafuegos** con iptables (política `DROP` en entrada y salida, IPv4 e IPv6). Solo se permite:
  - Entrada: SSH y ping desde la red de datos; HTTP desde el balanceador (servidores web); MariaDB desde los servidores web (servidor de base de datos).
  - Salida: DNS al servidor configurado, HTTP/HTTPS (apt y la aplicación), SSH, NTP, ping y MariaDB hacia el servidor de base de datos (servidores web).
- Aplicación: `http://www.hueso.org` (apunta al balanceador). Estadísticas de HAProxy: `http://<IP_NAT_balanceador>:8404`.

## Roles de Ansible

Por orden de ejecución en `site.yaml`:

1. `commons` (`balanceadores`): espera a que la máquina responda por SSH, a tener salida a internet y a que termine cloud-init; recoge los facts, actualiza el sistema e instala las herramientas de administración (`paquetes_comunes`). Va primero porque el balanceador es la única máquina con salida directa a internet.
2. `router` (`balanceadores`): activa el reenvío de paquetes y carga las reglas de NAT y reenvío con `iptables-persistent`. Tiene que estar listo antes de preparar los servidores, que solo salen a internet por el balanceador.
3. `commons` (`servidores`): lo mismo que en el balanceador, ya con salida a internet.
4. `cortafuegos` (`servidores`): quita `ufw` (Ubuntu) y carga las reglas de IPv4 e IPv6 con `iptables-persistent`. Lo que abre cada grupo está en `cortafuegos_entrada` y `cortafuegos_salida` de su `group_vars`.
5. `bd` (`servidores_bd`): MariaDB, la base de datos y un usuario por cada servidor web.
6. `web` (`servidores_web`): Apache, PHP, la aplicación y su virtual host. Añade la cabecera `X-Servidor` con el nombre del servidor que atiende.
7. `balanceador` (`balanceadores`): HAProxy con los servidores web como backend. La lista de servidores sale del grupo `servidores_web` del inventario.

## Requisitos

- libvirt/KVM, con acceso a `qemu:///system`.
- Incus, con el usuario en el grupo `incus-admin`, y `jq` (OpenTofu los usa para obtener la IP del balanceador).
- Las imágenes base en el pool `default`.
- OpenTofu y Ansible, con las colecciones `community.mysql`, `community.general` y `ansible.posix`:
  ```
  ansible-galaxy collection install community.mysql community.general ansible.posix
  ```
- La clave SSH cuya parte pública está en `opentofu/cloud-init/user-*.yaml` (`ssh_authorized_keys`). Para usar otra, cámbiala en esos ficheros.

## Despliegue

```bash
cd opentofu
tofu init              # solo la primera vez
tofu apply

cd ../ansible
ansible-playbook site.yaml
```

`tofu apply` genera el inventario `ansible/hosts` a partir de `opentofu/inventario.tftpl`, con la IP del balanceador en la red NAT. No se edita a mano y no se sube al repositorio.

Para acceder por nombre desde el equipo, añade a `/etc/hosts` la línea que muestra el output `etc_hosts` (la IP del balanceador). Esa IP cambia cada vez que se recrea el escenario.

```bash
tofu output -raw etc_hosts
# 192.168.160.X www.hueso.org
```

Para destruirlo: `tofu destroy` (en `opentofu/`).

## Variables

**OpenTofu** (`opentofu/variables.tf`):
- Imágenes base: `base_image_debian` y `base_image_ubuntu`; imagen del contenedor: `incus-cloud`.
- Recursos: `memoria` y `vcpus` (VM), `cmemoria` (contenedor).
- `dominio`: solo para el output `etc_hosts`; debe coincidir con `dominio` de `ansible/group_vars/servidores_web.yaml`.

Las IP de la red de datos son estáticas: están en `opentofu/cloud-init/network-*-config.yaml`, y se repiten en `opentofu/inventario.tf` y `opentofu/output.tf`. Si se cambia alguna, hay que cambiarla en los tres sitios.

**Inventario** (`ansible/hosts`, generado por OpenTofu): `ansible_host` de cada máquina (la IP NAT del balanceador y la IP de datos de los servidores), `ip_datos` del balanceador y el `ProxyCommand` para llegar a los servidores.

**Ansible** (`ansible/group_vars/`):
- `all.yaml`: datos de la base de datos, versión de la aplicación y datos de red. Las IP de datos no se repiten aquí: se leen del inventario (`ansible_host` de los servidores e `ip_datos` del balanceador), y a partir de la del balanceador se calcula `red_datos`. `dns_servidores` tiene que coincidir con el DNS de `opentofu/cloud-init/network-*-config.yaml`.
- `servidores_web.yaml`: nombre del virtual host, `DocumentRoot` y reglas del cortafuegos.
- `servidores_bd.yaml`: ubicación de `schema.sql`, socket de MariaDB y reglas del cortafuegos.
- `balanceadores.yaml`: puerto y credenciales de la página de estadísticas de HAProxy, e interfaces del router (externa e interna).

## Comprobaciones

Los servidores solo están en la red de datos: se entra en ellos saltando por el balanceador (`-J`).

```bash
# IP de las máquinas e inventario generado (en opentofu/)
tofu output
cat ../ansible/hosts
BAL=$(tofu output -json balanceador | jq -r .ip1)
SSH="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -J debian@$BAL"

# Idempotencia: la segunda ejecución termina con changed=0
(cd ../ansible && ansible-playbook site.yaml)

# Balanceo: sin cookie, cada petición va a un servidor web distinto
for i in 1 2 3 4; do curl -sI http://www.hueso.org | grep -i x-servidor; done
# X-Servidor: server-web1
# X-Servidor: server-web2
# ...

# Persistencia: con la cookie, siempre el mismo servidor web
curl -s -c /tmp/cookie -o /dev/null http://www.hueso.org
for i in 1 2 3; do curl -sI -b /tmp/cookie http://www.hueso.org | grep -i x-servidor; done

# Alta disponibilidad: con un servidor web parado, el otro atiende todo
$SSH debian@10.0.50.3 "sudo systemctl stop apache2"
for i in 1 2 3; do curl -sI http://www.hueso.org | grep -i x-servidor; done
$SSH debian@10.0.50.3 "sudo systemctl start apache2"

# Router: los servidores salen a internet a través del balanceador
$SSH debian@10.0.50.3 "ip route; curl -sI https://deb.debian.org | head -1"

# Desde los dos servidores web la conexión a la base de datos funciona
$SSH debian@10.0.50.3 "mariadb -h 10.0.50.2 -u guestbook -p guestbook -e 'SELECT * FROM messages'"
$SSH debian@10.0.50.4 "mariadb -h 10.0.50.2 -u guestbook -p guestbook -e 'SELECT * FROM messages'"

# Desde otro sitio (server-db) se rechaza: Host '10.0.50.2' is not allowed to connect
$SSH ubuntu@10.0.50.2 "mariadb -h 10.0.50.2 -u guestbook -p guestbook"

# Cortafuegos: reglas cargadas, y el puerto 3306 cerrado desde el balanceador
$SSH ubuntu@10.0.50.2 "sudo iptables -L -n -v"
ssh debian@$BAL "timeout 3 bash -c '</dev/tcp/10.0.50.2/3306' && echo abierto || echo cerrado"

# Reproducibilidad
tofu destroy && tofu apply && (cd ../ansible && ansible-playbook site.yaml)
```
