#!/bin/bash

# Dossiers et chemins
PACKAGE_DIR="./offline_packages"
CONFIG_DIR="./config"
SERVICE_DIR="./systemd_services"
BACKUP_DIR="./backup"
DEST_DIR="/opt/hidden_you"

# Fichiers source et destination pour les scripts
SCRIPT_SOURCE="$SERVICE_DIR/start_hidden_me.sh"
SCRIPT_DEST="$DEST_DIR/start_hidden_me.sh"
FIREWALL_SCRIPT_SOURCE="$SERVICE_DIR/ufw_iptable_conf.sh"
FIREWALL_SCRIPT_DEST="$DEST_DIR/ufw_iptable_conf.sh"

# Fichiers de configuration source et destination
VPN_CONFIG_SOURCE="$CONFIG_DIR/protonvpn.ovpn"
VPN_CREDENTIALS_SOURCE="$CONFIG_DIR/vpn_proton_credentials.txt"
DNSCRYPT_CONFIG_SOURCE="$CONFIG_DIR/dnscrypt-proxy.toml"
PROXYCHAINS_CONFIG_SOURCE="$CONFIG_DIR/proxychains.conf"
PROXYCHAINS4_CONFIG_SOURCE="$CONFIG_DIR/proxychains4.conf"
TORRC_SOURCE="$CONFIG_DIR/torrc"

VPN_CONFIG_DEST="/etc/openvpn/protonvpn.ovpn"
VPN_CREDENTIALS_DEST="/etc/openvpn/vpn_proton_credentials.txt"
DNSCRYPT_CONFIG_DEST="/etc/dnscrypt-proxy/dnscrypt-proxy.toml"
PROXYCHAINS_CONFIG_DEST="/etc/proxychains.conf"
PROXYCHAINS4_CONFIG_DEST="/etc/proxychains4.conf"
TORRC_DEST="/etc/tor/torrc"

# Installation des paquets requis depuis le dossier hors ligne
echo "Installation des paquets requis depuis le dossier hors ligne..."
sudo dpkg -i "$PACKAGE_DIR"/*.deb || echo "Installation partiellement terminée - des paquets peuvent manquer"

# Fonction pour sauvegarder et copier un fichier de configuration
sauvegarder_et_copier() {
    local source_file=$1
    local dest_file=$2

    # Sauvegarder le fichier existant s'il est présent
    if [ -f "$dest_file" ]; then
        sudo cp "$dest_file" "$BACKUP_DIR/$(basename $dest_file).original.$(date +%F_%T)"
    fi
    
    # Copier le fichier de configuration
    sudo cp "$source_file" "$dest_file"
    sudo chmod 600 "$dest_file"
}

# Copie des fichiers de configuration VPN, Proxychains, Tor, et DNSCrypt
echo "Copie des fichiers de configuration aux emplacements requis..."
sauvegarder_et_copier "$VPN_CONFIG_SOURCE" "$VPN_CONFIG_DEST"
sauvegarder_et_copier "$VPN_CREDENTIALS_SOURCE" "$VPN_CREDENTIALS_DEST"
sauvegarder_et_copier "$PROXYCHAINS_CONFIG_SOURCE" "$PROXYCHAINS_CONFIG_DEST"
sauvegarder_et_copier "$PROXYCHAINS4_CONFIG_SOURCE" "$PROXYCHAINS4_CONFIG_DEST"
sauvegarder_et_copier "$DNSCRYPT_CONFIG_SOURCE" "$DNSCRYPT_CONFIG_DEST"
sauvegarder_et_copier "$TORRC_SOURCE" "$TORRC_DEST"

# Fonction pour copier l'exécutable dnscrypt-proxy
installer_executable_dnscrypt() {
    local source_exe="$CONFIG_DIR/dnscrypt-proxy"
    local dest_exe="/usr/local/bin/dnscrypt-proxy"

    # Copier l'exécutable
    sudo cp "$source_exe" "$dest_exe"
    sudo chmod +x "$dest_exe"
}

# Installation de l'exécutable dnscrypt-proxy
echo "Installation de l'exécutable dnscrypt-proxy..."
installer_executable_dnscrypt

# Verrouillage de /etc/resolv.conf pour éviter les modifications
echo "Configuration des DNS pour utiliser DNSCrypt et verrouillage de /etc/resolv.conf"
sudo bash -c "echo 'nameserver 127.0.2.1' > /etc/resolv.conf"
sudo chattr +i /etc/resolv.conf

# Création du répertoire pour les scripts
echo "Création du dossier $DEST_DIR et copie des scripts..."
sudo mkdir -p "$DEST_DIR"
sudo cp "$SCRIPT_SOURCE" "$SCRIPT_DEST"
sudo cp "$FIREWALL_SCRIPT_SOURCE" "$FIREWALL_SCRIPT_DEST"
sudo chmod +x "$DEST_DIR/"*.sh

# Création et activation du service UFW, IPTables et DNScrypt
echo "Création et activation de ufw_iptable_conf.service..."
sudo cp "$SERVICE_DIR/ufw_iptable_conf.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable ufw_iptable_conf.service
sudo systemctl enable dnscrypt-proxy

# Création du service Hidden_Me et activation
echo "Création et activation de Hidden_Me.service..."
sudo cp "$SERVICE_DIR/Hidden_Me.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable Hidden_Me.service

# Désactivation de l'IPv6 pour éviter les fuites
echo "Désactivation de l'IPv6 pour éviter les fuites..."
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

echo "Installation et configuration initiales terminées."

