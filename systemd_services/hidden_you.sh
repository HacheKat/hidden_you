#!/bin/bash

# Fonction pour vérifier le statut d'un service
check_service_status() {
    if ! systemctl is-active --quiet $1; then
        echo "Erreur : $1 n'a pas démarré correctement."
        exit 1
    else
        echo "$1 est actif."
    fi
}

# Démarrage de dnscrypt-proxy
echo "Démarrage de dnscrypt-proxy..."
sudo systemctl start dnscrypt-proxy
check_service_status dnscrypt-proxy

# Démarrage de Tor
echo "Démarrage de Tor..."
sudo systemctl start tor
check_service_status tor

# Test de Proxychains avec Tor
echo "Test de Proxychains avec Tor..."
proxychains4 curl -s ifconfig.me || { echo "Erreur avec Proxychains"; exit 1; }

# Vérification et activation du pare-feu UFW si nécessaire
echo "Vérification de l'état actuel du pare-feu UFW..."
if ! sudo ufw status | grep -q "active"; then
    echo "Activation du pare-feu UFW avec les règles configurées..."
    sudo ufw enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 9050/tcp   # Port de Tor pour Proxychains
    sudo ufw allow 53/tcp      # Port DNS pour dnscrypt-proxy
    sudo ufw reload
else
    echo "Le pare-feu UFW est déjà actif."
fi
echo "Statut UFW :"
sudo ufw status verbose

# Démarrage de OpenVPN pour test et arrêt
echo "Démarrage du test VPN avec OpenVPN..."
sudo openvpn --config /etc/openvpn/protonvpn.ovpn --auth-user-pass /etc/openvpn/vpn_proton_credentials.txt --daemon
sleep 5  # Attendre pour l'établissement de la connexion
curl -s ifconfig.me
sudo pkill openvpn
echo "Test VPN terminé, OpenVPN arrêté."

echo "Tous les services de sécurité ont été démarrés avec succès."

