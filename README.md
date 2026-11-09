# Proyecto 1: Infraestructura como código

Escenario creado con **OpenTofu** (libvirt) y configurado con **Ansible** para poner en producción la aplicación [guestbook_php](https://github.com/josedom24/guestbook_php) (PHP + MariaDB).

- `opentofu/`: el escenario (redes, máquinas y el inventario de Ansible).
- `ansible/`: la configuración (`site.yaml` con los roles `commons`, `bd`, `web` y `balanceador`).

## Escenario

```
                          Equipo anfitrión
                                 │
            red_nat  192.168.160.0/24  (NAT + DHCP)
     │                │                  │                  │
 eth0 (DHCP)      ens3 (DHCP)        ens3 (DHCP)        ens3 (DHCP)
┌────┴────────┐ ┌─────┴───────┐  ┌─────┴───────┐  ┌───────┴─────┐
│ balanceador │ │ server-web1 │  │ server-web2 │  │  server-db  │
│ LXC (Incus) │ │  Debian 13  │  │  Debian 13  │  │ Ubuntu 26.04│
│   HAProxy   │ │ Apache+PHP  │  │ Apache+PHP  │  │   MariaDB   │
└────┬────────┘ └─────┬───────┘  └─────┬───────┘  └───────┬─────┘
 eth1 10.0.50.1   ens4 10.0.50.3   ens4 10.0.50.4   ens4 10.0.50.2
     │                │                  │                  │
            red_datos  10.0.50.0/24  (muy aislada, IP estáticas)
```

| Máquina | Tipo | Sistema | Red NAT (`red_nat`) | Red de datos (`red_datos`) | Grupo de Ansible |
|---|---|---|---|---|---|
| `balanceador` | Contenedor LXC (Incus) | Debian 13 | DHCP | 10.0.50.1/24 | `balanceadores` |
| `server-web1` | VM (libvirt) | Debian 13 | DHCP | 10.0.50.3/24 | `servidores_web` |
| `server-web2` | VM (libvirt) | Debian 13 | DHCP | 10.0.50.4/24 | `servidores_web` |
| `server-db` | VM (libvirt) | Ubuntu 26.04 | DHCP | 10.0.50.2/24 | `servidores_bd` |

- Las VM son clones ligeros de las imágenes base `debian13-base1.qcow2` y `ubuntu2604-base.qcow2` del pool `default`. El balanceador es un contenedor Incus (`images:debian/13/cloud`) conectado a los dos bridges de libvirt.
- HAProxy recibe las peticiones por la red NAT y las reparte (`roundrobin`) entre los dos servidores web por la red de datos. Con una cookie (`SERVIDOR`) cada navegador se queda en el mismo servidor web, porque la aplicación guarda el token CSRF en la sesión de PHP, que es local de cada servidor.
- Los dos servidores web comparten la misma base de datos. MariaDB solo escucha en la red de datos, y el usuario de la aplicación solo puede conectarse desde las IP de los servidores web en esa red.
- Aplicación: `http://www.hueso.org` (apunta al balanceador). Estadísticas de HAProxy: `http://<IP_NAT_balanceador>:8404`.

## Roles de Ansible

- `commons` (todas las máquinas): espera a que respondan por SSH y a que termine cloud-init, recoge los facts, actualiza el sistema e instala las herramientas de administración (`paquetes_comunes`). No instala nada de ningún servicio.
- `bd` (`servidores_bd`): MariaDB, la base de datos y un usuario por cada servidor web.
- `web` (`servidores_web`): Apache, PHP, la aplicación y su virtual host. Añade la cabecera `X-Servidor` con el nombre del servidor que atiende.
- `balanceador` (`balanceadores`): HAProxy con los servidores web como backend. La lista de servidores sale del grupo `servidores_web` del inventario.

## Requisitos

- libvirt/KVM, con acceso a `qemu:///system`.
- Incus, con el usuario en el grupo `incus-admin`, y `jq` (OpenTofu los usa para obtener la IP del balanceador).
- Las imágenes base en el pool `default`.
- OpenTofu y Ansible, con las colecciones `community.mysql` y `community.general`:
  ```
  ansible-galaxy collection install community.mysql community.general
  ```
- Una clave SSH en `~/.ssh/id_rsa.pub` (se puede cambiar con la variable `ssh_public_key_path`).

## Despliegue

```bash
cd opentofu
tofu init              # solo la primera vez
tofu apply

cd ../ansible
ansible-playbook site.yaml
```

`tofu apply` genera el inventario `ansible/hosts` a partir de las IP de las máquinas. No se edita a mano y no se sube al repositorio.

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

**Ansible** (`ansible/group_vars/`):
- `all.yaml`: datos de la base de datos y versión de la aplicación. Las IP de datos no se repiten aquí: se leen de la variable `ip_datos` que OpenTofu escribe en el inventario.
- `servidores_web.yaml`: nombre del virtual host y `DocumentRoot`.
- `servidores_bd.yaml`: ubicación de `schema.sql`.
- `balanceadores.yaml`: puerto y credenciales de la página de estadísticas de HAProxy.

## Comprobaciones

```bash
# IP de las máquinas e inventario generado
tofu output
cat ../ansible/hosts

# Idempotencia: la segunda ejecución termina con changed=0
ansible-playbook site.yaml

# Balanceo: sin cookie, cada petición va a un servidor web distinto
for i in 1 2 3 4; do curl -sI http://www.hueso.org | grep -i x-servidor; done
# X-Servidor: server-web1
# X-Servidor: server-web2
# ...

# Persistencia: con la cookie, siempre el mismo servidor web
curl -s -c /tmp/cookie -o /dev/null http://www.hueso.org
for i in 1 2 3; do curl -sI -b /tmp/cookie http://www.hueso.org | grep -i x-servidor; done

# Alta disponibilidad: con un servidor web parado, el otro atiende todo
ssh debian@<IP_NAT_server-web1> "sudo systemctl stop apache2"
for i in 1 2 3; do curl -sI http://www.hueso.org | grep -i x-servidor; done
ssh debian@<IP_NAT_server-web1> "sudo systemctl start apache2"

# Desde los dos servidores web la conexión a la base de datos funciona
ssh debian@<IP_NAT_server-web1> "mariadb -h 10.0.50.2 -u guestbook -p guestbook -e 'SELECT * FROM messages'"
ssh debian@<IP_NAT_server-web2> "mariadb -h 10.0.50.2 -u guestbook -p guestbook -e 'SELECT * FROM messages'"

# Desde otro sitio (server-db) se rechaza: Host '10.0.50.2' is not allowed to connect
ssh ubuntu@<IP_NAT_server-db> "mariadb -h 10.0.50.2 -u guestbook -p guestbook"

# Desde el equipo, por la red NAT, el puerto 3306 está cerrado
nc -zv <IP_NAT_server-db> 3306

# Reproducibilidad
tofu destroy && tofu apply && (cd ../ansible && ansible-playbook site.yaml)
```
