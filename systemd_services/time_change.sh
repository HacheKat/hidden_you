#!/bin/bash
# Script pour changer l'heure système pour une valeur aléatoire

HOUR=$(shuf -i 0-23 -n 1)
MINUTE=$(shuf -i 0-59 -n 1)
sudo date +%T -s "$HOUR:$MINUTE:00"
