#!/bin/bash

echo "Bienvenue dans l'application de sécurité : HIDDEN YOU ??"
echo "Ce script va vous guider dans l'activation des services de sécurité avec validation étape par étape."

# Fonction pour vérifier le statut d'un service
check_service_status() {
    if ! systemctl is-active --quiet "$1"; then
        echo "Erreur : $1 n'a pas démarré correctement."
        exit 1
    else
        echo "$1 est actif."
    fi
}

# Fonction pour vérifier et afficher l'IP actuelle
check_ip() {
    local description="$1"
    local ip=$(curl -s ifconfig.me)
    echo "$description - Adresse IP actuelle : $ip"
    echo "$ip"
}

# Changer l'adresse MAC
configure_macchanger() {
    echo "Modification de l'adresse MAC..."
    sudo ifconfig wlan0 down
    sudo macchanger -r wlan0
    sudo ifconfig wlan0 up
    echo "Adresse MAC changée."
    read -p "Validez le changement d'adresse MAC pour continuer (y/n) : " mac_confirm
}

# 1. Démarrage de dnscrypt-proxy
echo "Démarrage de dnscrypt-proxy..."
sudo systemctl start dnscrypt-proxy
check_service_status dnscrypt-proxy
read -p "DNSCrypt démarré avec succès. Passez à l'étape suivante ? (y/n) : " dnscrypt_confirm

# 2. Démarrage du VPN (OpenVPN) et vérification de l'IP
echo "Démarrage du VPN avec OpenVPN..."
sudo openvpn --config /etc/openvpn/protonvpn.ovpn --auth-user-pass /etc/openvpn/vpn_proton_credentials.txt --daemon
sleep 5  # Attendre que la connexion VPN s'établisse
ip_vpn=$(check_ip "Après connexion VPN")
echo "Adresse IP après connexion VPN : $ip_vpn"
read -p "Confirmez pour passer à l'étape suivante (y/n) : " vpn_confirm

# 3. Démarrage de Tor et vérification de l'IP
echo "Démarrage de Tor..."
sudo systemctl start tor
check_service_status tor
sleep 5  # Attendre le démarrage de Tor
ip_tor=$(check_ip "Après démarrage de Tor")
echo "Adresse IP après démarrage de Tor : $ip_tor"
read -p "Confirmez pour passer à l'étape suivante (y/n) : " tor_confirm

# 4. Activation de Proxychains et validation de l'IP finale
echo "Configuration de Proxychains pour anonymiser les requêtes..."
proxychains4_ip=$(proxychains4 curl -s ifconfig.me)
echo "IP avec Proxychains : $proxychains4_ip"
read -p "Confirmez pour terminer la configuration (y/n) : " proxychains_confirm

# Vérifications avancées des paramètres d’anonymat
echo "Lancement des vérifications d’anonymat avancées..."

# Vérification de l'IP pour le VPN
echo "Vérification de l'IP actuelle..."
CURRENT_IP=$(curl -s ifconfig.me)
echo "IP actuelle : $CURRENT_IP"
if [[ "$CURRENT_IP" != "$ip_vpn" ]]; then
    echo "ALERTE : L'IP n'est pas celle du VPN !"
    exit 1
fi

# Vérification des DNS pour éviter les fuites
echo "Vérification des serveurs DNS..."
DNS_SERVERS=$(dig +short example.com)
echo "Serveurs DNS utilisés : $DNS_SERVERS"
if [[ "$DNS_SERVERS" != *"127.0.2.1"* ]]; then
    echo "ALERTE : Fuite DNS détectée !"
    exit 1
fi

# Vérification de l'adresse MAC
echo "Vérification de l'adresse MAC..."
CURRENT_MAC=$(ifconfig wlan0 | grep ether | awk '{print $2}')
echo "Adresse MAC actuelle : $CURRENT_MAC"
if [[ "$CURRENT_MAC" == "Ton_adresse_MAC_vraie" ]]; then
    echo "ALERTE : L'adresse MAC n'a pas été changée !"
    exit 1
fi

echo "Toutes les vérifications ont été validées avec succès."

# Activation de la connexion Wi-Fi si toutes les étapes sont validées
echo "Activation de la connexion Wi-Fi..."
nmcli device wifi connect "SSID" password "PASSWORD"  # Remplace "SSID" et "PASSWORD" par vos informations Wi-Fi

echo "Connexion internet activée."

