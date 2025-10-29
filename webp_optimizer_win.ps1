# webp_optimizer_win.ps1
# PowerShell (Windows only) — ImageMagick + cwebp
# Install: winget install ImageMagick.Q16-HDRI ; winget install --id=Google.Libwebp -e
# Run:    powershell -ExecutionPolicy Bypass -File .\webp_optimizer_win.ps1

# -------------------- Réglages --------------------
$max_dimension = 1920            # plus grande dimension
$target_size   = 1048576         # 1 Mo en bytes
$start_quality = 100             # qualité initiale
$min_quality   = 10              # stop si on atteint ça

# -------------------- Helpers --------------------
function Format-Bytes([long]$b) {
  if ($b -ge 1MB) { "{0:N1} MB" -f ($b/1MB) }
  elseif ($b -ge 1KB) { "{0:N0} KB" -f ($b/1KB) }
  else { "$b B" }
}

function Get-Dim([string]$p) {
  & magick identify -format "%wx%h" -- $p 2>$null
}

function Write-Summary([string]$src,[string]$dst,[int]$q,[int]$tries) {
  $srcInfo = Get-Item -LiteralPath $src
  $dstInfo = Get-Item -LiteralPath $dst

  $srcSize = $srcInfo.Length
  $dstSize = $dstInfo.Length
  $pct     = [math]::Round((1 - ($dstSize / [double]$srcSize)) * 100, 1)
  $srcDim  = Get-Dim $src
  $dstDim  = Get-Dim $dst
  $name    = Split-Path $src -Leaf

  $srcFmt  = (Format-Bytes $srcSize).PadLeft(7)
  $dstFmt  = (Format-Bytes $dstSize).PadLeft(7)
  $pctFmt  = ("{0,6}" -f "-$pct%")

  # Emojis en littéraux (compat PS5)
  $ok    = "✅"
  $arrow = "→"
  $down  = "🔻"
  $gear  = "🔧"
  $frame = "🖼️"

  Write-Host ""
  Write-Host "$ok $name" -ForegroundColor Green
  Write-Host "   ↳ $frame $srcDim $arrow $dstDim | $srcFmt $arrow $dstFmt | $down $pctFmt | $gear q=$q ($tries try)" -ForegroundColor DarkGray
}



# -------------------- Convertisseur --------------------
function Convert-ToWebP {
  param([string]$fileFullPath, [string]$rootDir, [string]$outRoot)

  $dir      = [System.IO.Path]::GetDirectoryName($fileFullPath)
  $fileName = [System.IO.Path]::GetFileNameWithoutExtension($fileFullPath)
  $ext      = [System.IO.Path]::GetExtension($fileFullPath)

  # Génère le chemin relatif depuis la racine
  $relativePath = $fileFullPath.Substring($rootDir.Length).TrimStart('\')
  $relativeDir  = Split-Path $relativePath -Parent

  # Crée le dossier équivalent dans /compressed
  $outDir = Join-Path $outRoot $relativeDir
  if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
  }

  $webpBase = Join-Path $outDir "$fileName.webp"
  $tempBase = Join-Path $dir "$fileName`_temp$ext"

  # Si déjà converti dans /compressed → skip
  if (Test-Path -LiteralPath $webpBase) {
    Write-Host "[SKIP] $(Split-Path $fileFullPath -Leaf) (déjà compressé)"
    return
  }

  # Copie + resize temporaire
  Copy-Item -LiteralPath $fileFullPath -Destination $tempBase -Force
  & magick $tempBase -resize "$($max_dimension)x$($max_dimension)>" $tempBase 2>$null

  if (-not (Test-Path -LiteralPath $tempBase)) {
    Write-Host "[ERR] resize manqué: $tempBase"
    return
  }

  # Boucle qualité
  $quality = $start_quality
  $tries   = 0
  do {
    $tries++

    if (Test-Path -LiteralPath $webpBase) {
      Remove-Item -LiteralPath $webpBase -Force -ErrorAction SilentlyContinue
    }

    $argList = @('-quiet','-q', $quality, '-o', $webpBase, '--', $tempBase)
    & cwebp @argList *> $null
    $exit = $LASTEXITCODE

    if ($exit -ne 0) {
      Remove-Item -LiteralPath $tempBase -ErrorAction SilentlyContinue
      Write-Host "[ERR] cwebp a échoué ($exit) -> $fileFullPath"
      return
    }

    if (-not (Test-Path -LiteralPath $webpBase)) {
      Remove-Item -LiteralPath $tempBase -ErrorAction SilentlyContinue
      Write-Host "[ERR] sortie manquante: $webpBase"
      return
    }

    $new_size = (Get-Item -LiteralPath $webpBase).Length
    if ($new_size -le $target_size -or $quality -le $min_quality) { break }
    else { $quality -= 10 }
  } while ($true)

  # Nettoyage + résumé
  Remove-Item -LiteralPath $tempBase -ErrorAction SilentlyContinue
  Write-Summary -src $fileFullPath -dst $webpBase -q $quality -tries $tries
}

# -------------------- Lancement --------------------
$ROOT = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Path $MyInvocation.MyCommand.Definition -Parent }
$OUT_DIR = Join-Path $ROOT 'compressed'

if (-not (Test-Path -LiteralPath $OUT_DIR)) {
  New-Item -ItemType Directory -Path $OUT_DIR | Out-Null
}

Get-ChildItem -Path $ROOT -Recurse -File |
  Where-Object { $_.Extension -match '\.(jpg|jpeg|png|tif|tiff|bmp|gif)$' } |
  ForEach-Object { Convert-ToWebP -fileFullPath $_.FullName -rootDir $ROOT -outRoot $OUT_DIR }
