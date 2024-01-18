
#!/bin/bash

# https://github.com/sha0lean/webp_optimizer

# Script pour convertir des images en format WebP sans modifier les fichiers originaux
# Ce script recherche des images dans un dossier et ses sous-dossiers,
# les redimensionne pour que la plus grande dimension ne dépasse pas 1920px,
# et les convertit en WebP avec une taille inférieure à 1 Mo.

# Dépendances nécessaires : ImageMagick et WebP
# Télécharger ImageMagick :  https://imagemagick.org/script/download.php#windows

# Télécharger WebP :         https://developers.google.com/speed/webp/download

# Ajouter WebP dans le PATH (PowerShell en admin):
#      $Path = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
#      $WebPBinPath = "C:\Users\shao\libwebp_1.3.2\bin"
#      $NewPath = $Path + ";" + $WebPBinPath
#      [Environment]::SetEnvironmentVariable("Path", $NewPath, [EnvironmentVariableTarget]::Machine)

# Utilisation : chmod +x webp_optimizer.sh



# Chemin du dossier racine à partir duquel le script est exécuté
$DIR = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# Fonction pour convertir un fichier en WebP
Write-Host "----------------------------------------------------------------------------------`n"
function Convert-ToWebP {
    param (
        [String]$file
    )

    $max_dimension = 1920
    $target_size = 1048576
    $quality = 100

    $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $fileExtension = [System.IO.Path]::GetExtension($file)
    $fileDirectory = [System.IO.Path]::GetDirectoryName($file)
    $temp_file = Join-Path $fileDirectory "$($fileNameWithoutExtension)_temp$fileExtension"
    $newfile = Join-Path $fileDirectory "$fileNameWithoutExtension.webp"

    if (-Not (Test-Path $newfile)) {
        Copy-Item -Path $file -Destination $temp_file

        magick convert $temp_file -resize "$($max_dimension)x$max_dimension>" $temp_file

        do {
            & cwebp -q $quality $temp_file -o $newfile
            $new_size = (Get-Item $newfile).length
            if ($new_size -le $target_size -or $quality -le 10) {
                break
            }
            $quality -= 10
        } while ($true)

        Remove-Item -Path $temp_file

        $original_size = (Get-Item $file).length
        $size_diff = $original_size - $new_size
        $size_diff_mb = "{0:N2}" -f ($size_diff / 1MB)


        Write-Host "`n----------------------------------------------------------------------------------`n"
        Write-Host "Converti:  $file"
        Write-Host "       ->  $newfile"
        Write-Host ""
        Write-Host "Reduction de taille: $size_diff_mb Mo"
        Write-Host "----------------------------------------------------------------------------------`n"
    }
    else {
        Write-Host "Deja converti (ignoré): `n $file"
    }
}

# Exécution de la fonction pour chaque fichier image trouvé qui n'est pas déjà au format WebP
Get-ChildItem -Path $DIR -Recurse | 
    Where-Object { -not $_.PSIsContainer -and $_.Name -match "\.(jpg|jpeg|png|tiff|bmp|gif)$" -and -not $_.Name.EndsWith('.webp') } |
    ForEach-Object {
        Convert-ToWebP -file $_.FullName
    }
