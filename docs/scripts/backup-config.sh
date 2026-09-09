#!/bin/bash
#
# backup-config.sh - Sauvegarde de la configuration du serveur Starfleet
# Sauvegarde : reseau, services, PKI, annuaire LDAP, liste des paquets
#
# Usage   : ./backup-config.sh
# Cron    : 0 2 * * * /opt/backup/backup-config.sh >> /var/log/backup-starfleet.log 2>&1
#

set -e

# --- Variables ---
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/starfleet"
WORK_DIR="/tmp/backup_${DATE}"
ARCHIVE="${BACKUP_DIR}/starfleet_config_${DATE}.tar.gz"

echo "=== Sauvegarde de la configuration Starfleet - ${DATE} ==="

# --- Preparation ---
mkdir -p "${WORK_DIR}"
mkdir -p "${BACKUP_DIR}"

# --- 1. Configuration reseau ---
echo "[1/6] Configuration reseau..."
mkdir -p "${WORK_DIR}/reseau"
cp /etc/network/interfaces          "${WORK_DIR}/reseau/" 2>/dev/null || true
cp /etc/nftables.conf               "${WORK_DIR}/reseau/" 2>/dev/null || true
cp /etc/resolv.conf                 "${WORK_DIR}/reseau/" 2>/dev/null || true
cp /etc/sysctl.d/99-forwarding.conf "${WORK_DIR}/reseau/" 2>/dev/null || true

# --- 2. Services DNS / DHCP ---
echo "[2/6] DNS et DHCP..."
mkdir -p "${WORK_DIR}/dns-dhcp"
cp -r /etc/bind                     "${WORK_DIR}/dns-dhcp/" 2>/dev/null || true
cp -r /etc/dhcp                     "${WORK_DIR}/dns-dhcp/" 2>/dev/null || true
cp /etc/default/isc-dhcp-server     "${WORK_DIR}/dns-dhcp/" 2>/dev/null || true

# --- 3. Web (Nginx, PHP, vsftpd) ---
echo "[3/6] Web, PHP, FTP..."
mkdir -p "${WORK_DIR}/web"
cp -r /etc/nginx                    "${WORK_DIR}/web/" 2>/dev/null || true
cp /etc/vsftpd.conf                 "${WORK_DIR}/web/" 2>/dev/null || true
cp /etc/vsftpd.userlist             "${WORK_DIR}/web/" 2>/dev/null || true
ls /etc/php                       > "${WORK_DIR}/web/php-versions.txt" 2>/dev/null || true

# --- 4. PKI (certificats) ---
echo "[4/6] Certificats SSL..."
cp -r /etc/ssl/starfleet            "${WORK_DIR}/pki" 2>/dev/null || true

# --- 5. Annuaire LDAP (dump) ---
echo "[5/6] Annuaire LDAP..."
mkdir -p "${WORK_DIR}/ldap"
slapcat -n 1 > "${WORK_DIR}/ldap/data.ldif"   2>/dev/null || true
slapcat -n 0 > "${WORK_DIR}/ldap/config.ldif" 2>/dev/null || true

# --- 6. Liste des paquets et services ---
echo "[6/6] Paquets et services..."
mkdir -p "${WORK_DIR}/systeme"
dpkg --get-selections > "${WORK_DIR}/systeme/paquets.txt"
systemctl list-units --type=service --state=running \
    > "${WORK_DIR}/systeme/services-actifs.txt"
cp -r /etc/apt/sources.list.d       "${WORK_DIR}/systeme/" 2>/dev/null || true

# --- Compression ---
echo "Compression de l'archive..."
tar czf "${ARCHIVE}" -C "${WORK_DIR}" .

# --- Nettoyage ---
rm -rf "${WORK_DIR}"

# --- Rotation : garder les 7 dernieres sauvegardes ---
ls -1t "${BACKUP_DIR}"/starfleet_config_*.tar.gz 2>/dev/null \
    | tail -n +8 | xargs -r rm -f

echo "=== Sauvegarde terminee : ${ARCHIVE} ==="
ls -lh "${ARCHIVE}"
