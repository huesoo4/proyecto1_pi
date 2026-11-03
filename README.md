# Proyecto 1: Infraestructura como código

Escenario creado con **OpenTofu** (libvirt) y configurado con **Ansible** para poner en producción la aplicación [guestbook_php](https://github.com/josedom24/guestbook_php) (PHP + MariaDB).

- `opentofu/`: el escenario (redes, máquinas y el inventario de Ansible).
- `ansible/`: la configuración (`site.yaml` con los roles `commons`, `bd` y `web`).

## Escenario

```
                 Equipo anfitrión
                       │
        p1-nat  192.168.150.0/24  (NAT + DHCP)
           │                          │
      ens3 (DHCP)                ens3 (DHCP)
   ┌───────┴───────┐          ┌───────┴───────┐
   │      web      │          │       bd      │
   │   Debian 13   │          │ Ubuntu 26.04  │
   │ Apache + PHP  │          │    MariaDB    │
   └───────┬───────┘          └───────┬───────┘
     ens4 10.0.50.10            ens4 10.0.50.20
           │                          │
        p1-datos  10.0.50.0/24  (muy aislada, IP estáticas)
```

| Máquina | Sistema | Red NAT (`p1-nat`) | Red de datos (`p1-datos`) | Grupo de Ansible |
|---|---|---|---|---|
| `web` | Debian 13 | DHCP (192.168.150.0/24) | 10.0.50.10/24 | `servidores_web` |
| `bd` | Ubuntu 26.04 | DHCP (192.168.150.0/24) | 10.0.50.20/24 | `servidores_bd` |

- Las máquinas son clones ligeros de las imágenes base `debian13-base1.qcow2` y `ubuntu2604-base.qcow2` del pool `default`.
- MariaDB solo escucha en la red de datos, y el usuario de la aplicación solo puede conectarse desde la IP de `web` en esa red.
- Aplicación: `http://www.lopezhueso.org`.

## Requisitos

- libvirt/KVM, con acceso a `qemu:///system`.
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

Para acceder por nombre desde el equipo, añade a `/etc/hosts` la línea que muestra el output `etc_hosts`. La IP de `web` cambia cada vez que se recrea el escenario.

```bash
tofu output -raw etc_hosts
# 192.168.150.X www.lopezhueso.org
```

Para destruirlo: `tofu destroy` (en `opentofu/`).

## Variables

**OpenTofu** (`opentofu/variables.tf`):
- Imágenes base: `base_image_debian` y `base_image_ubuntu`.

**Ansible** (`ansible/group_vars/`):
- `all.yaml`: datos de la base de datos y versión de la aplicación. Las IP de datos no se repiten aquí: se leen de la variable `ip_datos` que OpenTofu escribe en el inventario.
- `servidores_web.yaml`: nombre del virtual host y `DocumentRoot`.
- `servidores_bd.yaml`: ubicación de `schema.sql`.

## Comprobaciones

```bash
# IP de las máquinas e inventario generado
tofu output
cat ../ansible/hosts

# Idempotencia: la segunda ejecución termina con changed=0
ansible-playbook site.yaml

# Desde web la conexión a la base de datos funciona
ssh debian@<IP_NAT_web> "mariadb -h 10.0.50.20 -u guestbook -p guestbook -e 'SELECT * FROM messages'"

# Desde otro sitio (bd) se rechaza: Host '10.0.50.20' is not allowed to connect
ssh ubuntu@<IP_NAT_bd> "mariadb -h 10.0.50.20 -u guestbook -p guestbook"

# Desde el equipo, por la red NAT, el puerto 3306 está cerrado
nc -zv <IP_NAT_bd> 3306

# Reproducibilidad
tofu destroy && tofu apply && (cd ../ansible && ansible-playbook site.yaml)
```
