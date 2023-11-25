# 🛠 WebP Image Optimizer 🏞 ![Static Badge](https://img.shields.io/badge/self_made-with_love-pink)

## 📝 Description

Le "WebP Image Optimizer" est un script Bash pour convertir automatiquement les images en format WebP, en les redimensionnant et en les compressant pour atteindre une taille cible, tout en préservant la qualité.

Le but c'est de pouvoir upload ses assets et les optimiser en une commande.

## 🔄 How it work

- ### Repertorie toute les images.
  - Il utilise `find` pour rechercher **tous les fichiers images** (_non-WebP_) **dans le répertoire** et **ses sous-dossiers**. Généralement dans `/assets`.
- ### Pour chaque Fichier :
  - **Vérification du format**
    - `JPG`, `JPEG`, `PNG`, `TIFF`, `BMP` ou `GIF`.
  - **Redimensionnement**
    - Redimensionne l'image pour que **sa plus grande dimension.** (_largeur ou hauteur_) ne dépasse pas `1920px`.
  - **Conversion en `.webp` et ajustement de la Qualité** (_si nécessaire_).
    - La boucle `while` continue de réduire la qualité **par paliers de 10** avec `cwebp -q $quality` jusqu'à ce que la taille du fichier soit **inférieure ou égale à `1 Mo`**.

## Explications de mes paramètres 🌐

| Aspect              |                          | Raison                                                                                                                                                                                        |
| ------------------- | ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Format**          | `WebP`                   | - **Performance accrue** : Meilleure compression que JPEG/PNG.<br>- **Qualité préservée** : Maintient une haute qualité d'image.                                                              |
| **Dimensionnement** | `1920`<br> `x`<br>`1080` | - **Compatibilité écran** : Inutile de dépasser cette résolution.<br>- **Équilibre taille/qualité** : Réduit la taille du fichier tout en conservant des détails suffisants.                  |
| **Compression**     | `< 1Mo`                  | - **Rapidité de chargement** : Fichiers plus petits pour des temps de chargement plus rapides.<br>- **Économie de bande passante** : Réduit la consommation de données pour les utilisateurs. |

---

<br>

## Prérequis & Installation

- `WebP` & `ImageMagick`.

```
brew install imagemagick webp
```

- Rend le fichier executable par la `CLI`.

```bash
chmod +x webp_image_optimizer.sh
```

## Utilisation

Exécutez le script dans le répertoire contenant vos images :

```bash
./webp_optimizer.sh
```

ou rajouter ce script dans `package.json``

```bash
"scripts": {
    "optimg": "bash src/assets/webp_optimizer.sh"
}
```

## Paramètres Configurables

- `max_dimension` : Hauteur ou Largeur maximale (_par défaut 1980px_)
- `target_size` : Taille cible du fichier (_par défaut 1 Mo_)
