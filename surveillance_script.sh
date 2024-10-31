#!/bin/bash

echo "Surveillance de l'intégrité des fichiers critiques en cours..."

# Fonction de vérification de l'intégrité des fichiers
verify_file_integrity() {
    local file=$1
    local checksum=$2
    current_checksum=$(md5sum "$file" | awk '{ print $1 }')
    if [ "$current_checksum" != "$checksum" ]; then
        echo "Alerte : $file a été modifié !"
        # Action supplémentaire ici, comme alerter l'utilisateur ou restaurer le fichier
    else
        echo "$file est inchangé."
    fi
}

# Fichiers à surveiller avec leurs checksums initiaux
declare -A files_to_monitor=(
    ["/etc/resolv.conf"]="fe0b86955e4eb444f17f54d086580b1f"
    # Ajoutez d'autres fichiers si nécessaire
)

# Boucle de surveillance continue
while true; do
    for file in "${!files_to_monitor[@]}"; do
        verify_file_integrity "$file" "${files_to_monitor[$file]}"
    done
    sleep 300  # Intervalle de 5 minutes
done

