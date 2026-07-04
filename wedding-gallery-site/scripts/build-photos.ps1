# ==============================
# Wedding gallery photo builder
# ==============================

# 1. Путь к проекту
$ProjectRoot = "D:\Work\Personal\Wedding-gallery\wedding-gallery-site"

# 2. Путь к исходным фото
# СЮДА вставь свою папку с оригинальными / исходными фотографиями
$SourceDir = "D:\PUT\YOUR\SOURCE\PHOTOS\HERE"

# 3. Выходные папки проекта
$FullDir = Join-Path $ProjectRoot "public\photos\full"
$ThumbsDir = Join-Path $ProjectRoot "public\photos\thumbs"
$DownloadsDir = Join-Path $ProjectRoot "public\photos\downloads"
$JpgDownloadsDir = Join-Path $DownloadsDir "jpg"
$PhotosJsPath = Join-Path $ProjectRoot "src\photos.js"
$ZipPath = Join-Path $DownloadsDir "wedding-all.zip"

# 4. Настройки качества
$FullSize = "2200x2200>"
$FullQuality = 88

$ThumbSize = "1200x1200>"
$ThumbQuality = 84

$DownloadSize = "3200x3200>"
$DownloadQuality = 94

# 5. Нужно ли очищать старые сгенерированные файлы перед сборкой
$CleanOutput = $true

# ==============================
# Checks
# ==============================

if (-not (Test-Path $SourceDir)) {
  Write-Host "Source folder does not exist:" $SourceDir -ForegroundColor Red
  exit 1
}

if (-not (Get-Command magick -ErrorAction SilentlyContinue)) {
  Write-Host "ImageMagick is not installed or magick is not available in PATH." -ForegroundColor Red
  Write-Host "Install it with: winget install ImageMagick.ImageMagick"
  exit 1
}

# ==============================
# Prepare folders
# ==============================

New-Item -ItemType Directory -Force -Path $FullDir | Out-Null
New-Item -ItemType Directory -Force -Path $ThumbsDir | Out-Null
New-Item -ItemType Directory -Force -Path $DownloadsDir | Out-Null
New-Item -ItemType Directory -Force -Path $JpgDownloadsDir | Out-Null

if ($CleanOutput) {
  Write-Host "Cleaning generated folders..."

  Remove-Item (Join-Path $FullDir "*") -Force -ErrorAction SilentlyContinue
  Remove-Item (Join-Path $ThumbsDir "*") -Force -ErrorAction SilentlyContinue
  Remove-Item (Join-Path $JpgDownloadsDir "*") -Force -ErrorAction SilentlyContinue

  if (Test-Path $ZipPath) {
    Remove-Item $ZipPath -Force
  }
}

# ==============================
# Read source photos
# ==============================

$SupportedExtensions = @(".jpg", ".jpeg", ".png", ".webp")

$Photos = Get-ChildItem $SourceDir -File |
  Where-Object { $SupportedExtensions -contains $_.Extension.ToLower() } |
  Sort-Object Name

if ($Photos.Count -eq 0) {
  Write-Host "No supported photos found in:" $SourceDir -ForegroundColor Yellow
  exit 0
}

$PhotoItems = @()
$Index = 1

foreach ($Photo in $Photos) {
  $SafeNumber = "{0:D3}" -f $Index
  $OutputBaseName = "photo-$SafeNumber"

  $FullWebpName = "$OutputBaseName.webp"
  $ThumbWebpName = "$OutputBaseName-thumb.webp"
  $DownloadJpgName = "$OutputBaseName.jpg"

  $FullWebpPath = Join-Path $FullDir $FullWebpName
  $ThumbWebpPath = Join-Path $ThumbsDir $ThumbWebpName
  $DownloadJpgPath = Join-Path $JpgDownloadsDir $DownloadJpgName

  Write-Host "Processing $($Photo.Name) -> $OutputBaseName"

  # Большая webp-версия для просмотра на сайте
  magick $Photo.FullName -auto-orient -resize $FullSize -quality $FullQuality $FullWebpPath

  # Крупное превью для карточек галереи
  magick $Photo.FullName -auto-orient -resize $ThumbSize -quality $ThumbQuality $ThumbWebpPath

  # JPG-версия для скачивания
  magick $Photo.FullName -auto-orient -resize $DownloadSize -quality $DownloadQuality $DownloadJpgPath

  $PhotoItems += [PSCustomObject]@{
    title = "Фото $Index"
    thumb = "/photos/thumbs/$ThumbWebpName"
    full = "/photos/full/$FullWebpName"
    download = "/photos/downloads/jpg/$DownloadJpgName"
  }

  $Index++
}

# ==============================
# Create ZIP archive
# ==============================

Write-Host "Creating ZIP archive..."

if (Test-Path $ZipPath) {
  Remove-Item $ZipPath -Force
}

Compress-Archive -Path (Join-Path $JpgDownloadsDir "*") -DestinationPath $ZipPath

# ==============================
# Generate src/photos.js
# ==============================

Write-Host "Generating photos.js..."

$PhotosJs = "window.WEDDING_PHOTOS = [" + "`n"

for ($i = 0; $i -lt $PhotoItems.Count; $i++) {
  $Item = $PhotoItems[$i]
  $Comma = if ($i -lt $PhotoItems.Count - 1) { "," } else { "" }

  $PhotosJs += "  {" + "`n"
  $PhotosJs += "    title: `"$($Item.title)`"," + "`n"
  $PhotosJs += "    thumb: `"$($Item.thumb)`"," + "`n"
  $PhotosJs += "    full: `"$($Item.full)`"," + "`n"
  $PhotosJs += "    download: `"$($Item.download)`"" + "`n"
  $PhotosJs += "  }$Comma" + "`n"
}

$PhotosJs += "];" + "`n"

Set-Content -Path $PhotosJsPath -Value $PhotosJs -Encoding UTF8

# ==============================
# Done
# ==============================

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "Source photos:       $SourceDir"
Write-Host "Full webp files:     $FullDir"
Write-Host "Thumbnail files:     $ThumbsDir"
Write-Host "Download JPG files:  $JpgDownloadsDir"
Write-Host "ZIP archive:         $ZipPath"
Write-Host "Generated JS:        $PhotosJsPath"