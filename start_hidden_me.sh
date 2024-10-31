#!/bin/bash

echo "Bienvenue dans l'application de sécurité : HIDDEN YOU"
echo "Ce script va vous guider dans l'activation des services de sécurité avec validation étape par étape."

# Fonction de vérification du statut des services
check_service_status() {
    if ! systemctl is-active --quiet "$1"; then
        echo "Erreur : $1 n'a pas démarré correctement."
        exit 1
    else
        echo "$1 est actif."
    fi
}

# Fonction de vérification de l'intégrité des fichiers critiques
verify_file_integrity() {
    local file=$1
    local checksum=$2
    current_checksum=$(md5sum $file | awk '{ print $1 }')
    if [ "$current_checksum" != "$checksum" ]; then
        echo "Alerte : $file a été modifié !"
        # Restaurer ou envoyer une alerte si nécessaire
    else
        echo "$file est inchangé."
    fi
}

# Fonction de vérification et affichage de l'IP
check_ip() {
    local description="$1"
    local ip=$(curl -s ifconfig.me)
    echo "$description - Adresse IP actuelle : ${ip:0:3}...${ip: -3}"
    echo "$ip"
}

# Fonction pour activer le Kill Switch avec UFW
configure_ufw_kill_switch() {
    echo "Configuration du Kill Switch avec UFW..."
    sudo ufw default deny incoming
    sudo ufw default deny outgoing
    sudo ufw allow out on tun0  # VPN
    sudo ufw allow out 9050/tcp # Tor
    sudo ufw allow out 53/tcp   # DNSCrypt
    sudo ufw reload
    echo "Kill Switch configuré."
}

# Étape 1 : Activation d'UFW et vérification de l'IP brute
echo "Étape 1 : Activation du pare-feu UFW et vérification de l'IP brute"
if ! sudo ufw status | grep -q "active"; then
    configure_ufw_kill_switch
    sudo ufw enable
fi
sudo ufw status verbose
ip_brute=$(check_ip "IP brute initiale")
read -p "Statut du pare-feu UFW : Actif. IP brute : ${ip_brute:0:3}...${ip_brute: -3}. Voulez-vous continuer ? (y/n) : " confirm
[[ $confirm != "y" ]] && exit 1

# Étape 2 : Configuration des DNS avec DNSCrypt et verrouillage de resolv.conf
echo "Étape 2 : Configuration de DNSCrypt et verrouillage de /etc/resolv.conf"
sudo bash -c "echo 'nameserver 127.0.2.1' > /etc/resolv.conf"
sudo chattr +i /etc/resolv.conf
sudo systemctl start dnscrypt-proxy
check_service_status dnscrypt-proxy
read -p "DNSCrypt démarré et résolveur DNS configuré. Voulez-vous continuer ? (y/n) : " confirm
[[ $confirm != "y" ]] && exit 1

# Étape 3 : Connexion au VPN avec OpenVPN et vérification de l'IP
echo "Étape 3 : Connexion au VPN avec OpenVPN"
sudo openvpn --config /etc/openvpn/protonvpn.ovpn --auth-user-pass /etc/openvpn/vpn_proton_credentials.txt --daemon
sleep 5
ip_vpn=$(check_ip "Après connexion VPN")
echo "L'IP brute (${ip_brute:0:3}...) est maintenant cachée. Nouvelle IP : ${ip_vpn:0:3}...${ip_vpn: -3}"
read -p "IP VPN validée. Voulez-vous continuer ? (y/n) : " confirm
[[ $confirm != "y" ]] && exit 1

# Étape 4 : Démarrage de Tor et vérification de l'IP
echo "Étape 4 : Démarrage de Tor et vérification de l'IP"
sudo systemctl start tor
check_service_status tor
sleep 5
ip_tor=$(check_ip "Après démarrage de Tor")
echo "IP avec Tor activé : ${ip_tor:0:3}...${ip_tor: -3}"
read -p "Tor activé et IP modifiée. Voulez-vous continuer ? (y/n) : " confirm
[[ $confirm != "y" ]] && exit 1

# Étape 5 : Test de Proxychains pour garantir l'anonymisation
echo "Étape 5 : Test de Proxychains avec Tor et VPN actifs"
proxychains4_ip=$(proxychains4 curl -s ifconfig.me)
echo "IP finale avec Proxychains : ${proxychains4_ip:0:3}...${proxychains4_ip: -3}"
read -p "Configuration Proxychains validée. Voulez-vous continuer ? (y/n) : " confirm
[[ $confirm != "y" ]] && exit 1

# Étape 6 : Modification de l'adresse MAC
echo "Étape 6 : Modification de l'adresse MAC"
sudo ifconfig wlan0 down
sudo macchanger -r wlan0
sudo ifconfig wlan0 up
CURRENT_MAC=$(ifconfig wlan0 | grep ether | awk '{print $2}')
echo "Nouvelle adresse MAC : ${CURRENT_MAC:0:9}..."
read -p "Adresse MAC modifiée avec succès. Voulez-vous continuer ? (y/n) : " confirm
[[ $confirm != "y" ]] && exit 1

# Étape 7 : Connexion sécurisée Wi-Fi
echo "Étape 7 : Connexion Wi-Fi sécurisée"
nmcli device wifi connect "Redlyly" password "uijklm7856dsk"
echo "Connexion Wi-Fi réussie."

# Étape 8 : Lancement de Firefox et Terminal sécurisés
echo "Lancement de Firefox sous Proxychains..."
proxychains4 firefox &

echo "Lancement du terminal sécurisé via Proxychains..."
proxychains4 gnome-terminal &


# Message final pour lancer le script de surveillance
echo "La configuration de sécurité est en place et les applications sécurisées sont lancées."
echo "Pour activer la surveillance en temps réel de l'intégrité et des connexions, exécutez le script de surveillance."

# Demande pour lancer le script de surveillance
read -p "Voulez-vous lancer le script de surveillance en temps réel ? (y/n) : " confirm_surveillance
if [[ $confirm_surveillance == "y" ]]; then
    echo "Lancement du script de surveillance en arrière-plan..."
    ./surveillance_script.sh &
    echo "Le script de surveillance est en cours d'exécution."
else
    echo "Surveillance en temps réel non activée."
fi

