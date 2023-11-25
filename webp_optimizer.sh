#!/bin/bash
# Script pour convertir des images en format WebP sans modifier les fichiers originaux
# Ce script recherche des images dans un dossier et ses sous-dossiers,
# les redimensionne pour que la plus grande dimension ne dépasse pas 1920px,
# et les convertit en WebP avec une taille inférieure à 1 Mo.

# Dépendances nécessaires : ImageMagick et WebP
# Installation sur macOS : brew install imagemagick webp
# Utilisation : chmod +x webp_optimizer.sh
# Documentation WebP : https://developers.google.com/speed/webp/docs/cwebp?hl=fr
# Télécharger ImageMagick : https://imagemagick.org/script/download.php#macosx

# Chemin du dossier racine (où se trouve le script)
DIR=$(dirname "$0")

# Tableau pour stocker les fichiers ignorés
declare -a ignored_files

# Fonction pour convertir un fichier en WebP
webp_optimizer() {
	local file="$1"                               # Fichier d'entrée
	local temp_file="${file%.*}_temp.${file##*.}" # Fichier temporaire pour le traitement
	local newfile="${file%.*}.webp"               # Nom du fichier de sortie en WebP
	local max_dimension=1920                      # Dimension maximale pour le redimensionnement
	local target_size=1048576                     # Taille cible en octets (1 Mo)
	local quality=90                              # Qualité initiale pour la conversion en WebP

	# Vérifie si le fichier est une image et n'est pas déjà au format WebP
	if [[ $file =~ \.(jpg|jpeg|png|tiff|bmp|gif)$ ]]; then
		# Vérifie si le fichier WebP existe déjà
		if [ ! -f "$newfile" ]; then
			# Copie le fichier original dans un fichier temporaire pour le traitement
			cp "$file" "$temp_file"

			# Redimensionne l'image temporaire pour que la plus grande dimension soit au maximum 1920px
			convert "$temp_file" -resize "${max_dimension}x${max_dimension}>" "$temp_file"

			# Boucle pour ajuster la qualité et atteindre la taille cible
			while :; do
				cwebp -q $quality "$temp_file" -o "$newfile" # Convertit en WebP avec la qualité actuelle
				local new_size=$(stat -f%z "$newfile")       # Taille du fichier WebP
				# Vérifie si la taille est inférieure à la taille cible ou si la qualité est minimale
				if [ $new_size -le $target_size ] || [ $quality -le 10 ]; then
					break
				fi
				quality=$((quality - 10)) # Réduit la qualité par paliers de 10
			done

			# Supprime le fichier temporaire après la conversion
			rm "$temp_file"

			local original_size=$(stat -f%z "$file")                            # Taille du fichier original
			local size_diff=$((original_size - new_size))                       # Différence de taille
			local size_diff_mb=$(echo "scale=2; $size_diff / 1024 / 1024" | bc) # Différence en Mo

			# Affiche les informations de conversion
			echo -e "Converti: $file -> $newfile"
			echo -e "Réduction de taille: $size_diff_mb Mo"
		else
			# Si le fichier WebP existe déjà, il est ignoré
			echo -e "Déjà converti (ignoré): $file"
		fi
	else
		# Ajoute les fichiers non-images au tableau des fichiers ignorés
		ignored_files+=("$file")
	fi
}
export -f convert_to_webp # Rend la fonction accessible pour find

# Début du script
echo -e "-------------------------------"
echo -e "\nDébut de la conversion des images...\n"

# Trouve et convertit les fichiers qui ne sont pas au format WebP
find "$DIR" -type f ! -name '*.webp' -exec bash -c 'convert_to_webp "$0"' {} \;

# Affiche les fichiers ignorés
if [ ${#ignored_files[@]} -ne 0 ]; then
	echo -e "-------------------------------"
	echo -e "\nFichiers ignorés :"
	for file in "${ignored_files[@]}"; do
		echo "$file"
	done
else
	echo -e "\nAucun fichier ignoré."
fi

# Fin du script
echo -e "-------------------------------"
echo -e "\nConversion terminée.\n"
