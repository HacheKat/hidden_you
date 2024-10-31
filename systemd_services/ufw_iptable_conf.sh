#!/bin/bash

echo "Configuration avancée du pare-feu avec UFW et IPTables"

# Désactiver firewalld s'il est actif pour éviter les conflits
if systemctl is-active --quiet firewalld; then
    echo "Désactivation de firewalld pour éviter les conflits avec UFW..."
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld
fi

# Activer UFW avec des règles de base
echo "Configuration des règles de base avec UFW..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Autoriser les services de sécurité
echo "Autorisation des services essentiels..."
sudo ufw allow 9050/tcp    # Port de Tor pour Proxychains
sudo ufw allow 53/tcp       # Port DNS pour dnscrypt-proxy
sudo ufw allow out on tun0  # Autoriser le trafic VPN sortant (interface tun0)

# Activer les règles supplémentaires avec IPTables
echo "Configuration de règles IPTables supplémentaires pour la sécurité..."

# Kill switch VPN : bloquer tout sauf tun0 (VPN)
sudo iptables -I OUTPUT ! -o tun0 -m state --state NEW,ESTABLISHED,RELATED -j REJECT

# Autoriser uniquement le trafic sortant sur les ports DNS (53), VPN (1194 pour OpenVPN), et Tor (9050)
sudo iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 9050 -j ACCEPT
sudo iptables -A OUTPUT -p udp --dport 1194 -j ACCEPT

# Activer les règles strictes pour bloquer les paquets ICMP (ping)
sudo iptables -A OUTPUT -p icmp -j DROP
sudo iptables -A INPUT -p icmp -j DROP

# Activer UFW avec les règles configurées
echo "Activation de UFW avec les règles configurées..."
sudo ufw enable

# Afficher le statut final d'UFW et des règles IPTables
echo "Statut final d'UFW :"
sudo ufw status verbose

echo "Règles IPTables appliquées :"
sudo iptables -L -v

