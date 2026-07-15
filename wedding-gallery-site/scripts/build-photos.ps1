param(
  [string]$SourceRoot
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
  $SourceRoot = Join-Path $ProjectRoot "incoming"
}

$SourceRoot = [System.IO.Path]::GetFullPath($SourceRoot)
$PhotosRoot = Join-Path $ProjectRoot "public\photos"
$ArchivesDir = Join-Path $PhotosRoot "downloads"
$PhotosJsPath = Join-Path $ProjectRoot "src\photos.js"

# JSON escapes keep this script compatible with Windows PowerShell 5 encoding.
$VenchanieTitle = '"\u0412\u0435\u043d\u0447\u0430\u043d\u0438\u0435"' | ConvertFrom-Json
$RospisTitle = '"\u0420\u043e\u0441\u043f\u0438\u0441\u044c"' | ConvertFrom-Json
$GulyaniaTitle = '"\u0413\u0443\u043b\u044f\u043d\u0438\u044f"' | ConvertFrom-Json
$May17 = '"17 \u043c\u0430\u044f 2026"' | ConvertFrom-Json
$May16 = '"16 \u043c\u0430\u044f 2026"' | ConvertFrom-Json
$May16To17 = '"16\u201317 \u043c\u0430\u044f 2026"' | ConvertFrom-Json

$Sections = @(
  [PSCustomObject]@{ id = "venchanie"; title = $VenchanieTitle; date = $May17; hero = "/src/images/heroes/venchanie.webp" },
  [PSCustomObject]@{ id = "rospis"; title = $RospisTitle; date = $May16; hero = "/src/images/heroes/rospis.webp" },
  [PSCustomObject]@{ id = "gulyania"; title = $GulyaniaTitle; date = $May16To17; hero = "/src/images/heroes/gulyania.webp" }
)

$Groups = @("best", "rest")
$SupportedExtensions = @(".jpg", ".jpeg", ".png", ".webp", ".tif", ".tiff")
$FullSize = "2800x2800>"
$FullQuality = 90
$ThumbSize = "1600x1600>"
$ThumbQuality = 88

function New-ZipArchive {
  param(
    [string]$Destination,
    [array]$Items
  )

  Add-Type -AssemblyName System.IO.Compression
  Add-Type -AssemblyName System.IO.Compression.FileSystem

  if (Test-Path -LiteralPath $Destination) {
    Remove-Item -LiteralPath $Destination -Force
  }

  $stream = [System.IO.File]::Open($Destination, [System.IO.FileMode]::CreateNew)
  try {
    $zip = New-Object System.IO.Compression.ZipArchive(
      $stream,
      [System.IO.Compression.ZipArchiveMode]::Create,
      $false
    )
    try {
      foreach ($item in $Items) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
          $zip,
          $item.path,
          $item.entry,
          [System.IO.Compression.CompressionLevel]::Optimal
        ) | Out-Null
      }
    }
    finally {
      $zip.Dispose()
    }
  }
  finally {
    $stream.Dispose()
  }
}

function Get-SupportedPhotos {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    return @()
  }

  return @(Get-ChildItem -LiteralPath $Path -File |
    Where-Object { $SupportedExtensions -contains $_.Extension.ToLowerInvariant() } |
    Sort-Object Name)
}

if (-not (Get-Command magick -ErrorAction SilentlyContinue)) {
  Write-Host "ImageMagick was not found." -ForegroundColor Red
  Write-Host "Install it once: winget install ImageMagick.ImageMagick"
  exit 1
}

if (-not (Test-Path -LiteralPath $SourceRoot)) {
  New-Item -ItemType Directory -Path $SourceRoot -Force | Out-Null
}

New-Item -ItemType Directory -Path $PhotosRoot -Force | Out-Null
New-Item -ItemType Directory -Path $ArchivesDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $ProjectRoot "src\images\heroes") -Force | Out-Null

Write-Host "Source photos: $SourceRoot" -ForegroundColor Cyan
Write-Host "List previews: up to 1600 px; fullscreen WebP: up to 2800 px."
Write-Host "Original files are copied without resizing.`n"

$ManifestSections = @()
$AllZipItems = @()

foreach ($Section in $Sections) {
  $SectionSource = Join-Path $SourceRoot $Section.id
  $SectionOutput = Join-Path $PhotosRoot $Section.id
  $ArchivePath = Join-Path $ArchivesDir "$($Section.id).zip"

  if (Test-Path -LiteralPath $SectionOutput) {
    Remove-Item -LiteralPath $SectionOutput -Recurse -Force
  }

  $SectionZipItems = @()
  $GroupManifests = @{}
  $SectionPhotoCount = 0

  foreach ($Group in $Groups) {
    $GroupSource = Join-Path $SectionSource $Group
    $GroupOutput = Join-Path $SectionOutput $Group
    $ThumbsDir = Join-Path $GroupOutput "thumbs"
    $FullDir = Join-Path $GroupOutput "full"
    $OriginalsDir = Join-Path $GroupOutput "originals"

    New-Item -ItemType Directory -Path $ThumbsDir -Force | Out-Null
    New-Item -ItemType Directory -Path $FullDir -Force | Out-Null
    New-Item -ItemType Directory -Path $OriginalsDir -Force | Out-Null

    $SourcePhotos = @(Get-SupportedPhotos -Path $GroupSource)

    # Backward compatibility: files directly in a section are considered rest.
    if ($Group -eq "rest") {
      $SourcePhotos += @(Get-SupportedPhotos -Path $SectionSource)
      $SourcePhotos = @($SourcePhotos | Sort-Object Name)
    }

    Write-Host "$($Section.title) / $Group`: $($SourcePhotos.Count) photos" -ForegroundColor Yellow
    $PhotoItems = @()
    $Index = 1

    foreach ($Photo in $SourcePhotos) {
      $Number = "{0:D3}" -f $Index
      $BaseName = "photo-$Number"
      $OriginalExtension = $Photo.Extension.ToLowerInvariant()
      $OriginalName = "$BaseName$OriginalExtension"
      $ThumbName = "$BaseName-thumb.webp"
      $FullName = "$BaseName.webp"
      $OriginalPath = Join-Path $OriginalsDir $OriginalName

      Write-Host "  [$Number/$($SourcePhotos.Count)] $($Photo.Name)"

      & magick $Photo.FullName -auto-orient -strip -resize $ThumbSize -quality $ThumbQuality -define webp:method=6 (Join-Path $ThumbsDir $ThumbName)
      if ($LASTEXITCODE -ne 0) { throw "Could not create a thumbnail for $($Photo.FullName)" }

      & magick $Photo.FullName -auto-orient -strip -resize $FullSize -quality $FullQuality -define webp:method=6 (Join-Path $FullDir $FullName)
      if ($LASTEXITCODE -ne 0) { throw "Could not create a full WebP for $($Photo.FullName)" }

      Copy-Item -LiteralPath $Photo.FullName -Destination $OriginalPath -Force

      $PhotoItems += [ordered]@{
        title = $Photo.BaseName
        thumb = "/photos/$($Section.id)/$Group/thumbs/$ThumbName"
        full = "/photos/$($Section.id)/$Group/full/$FullName"
        download = "/photos/$($Section.id)/$Group/originals/$OriginalName"
      }

      $SectionZipItems += [PSCustomObject]@{ path = $OriginalPath; entry = "$Group/$OriginalName" }
      $AllZipItems += [PSCustomObject]@{ path = $OriginalPath; entry = "$($Section.id)/$Group/$OriginalName" }
      $Index++
      $SectionPhotoCount++
    }

    $GroupManifests[$Group] = $PhotoItems
  }

  New-ZipArchive -Destination $ArchivePath -Items $SectionZipItems
  Write-Host "$($Section.title): $SectionPhotoCount photos total`n"

  $ManifestSections += [ordered]@{
    id = $Section.id
    title = $Section.title
    date = $Section.date
    hero = $Section.hero
    archive = "/photos/downloads/$($Section.id).zip"
    best = $GroupManifests["best"]
    rest = $GroupManifests["rest"]
  }
}

$HeroesSource = Join-Path $SourceRoot "heroes"
if (Test-Path -LiteralPath $HeroesSource) {
  foreach ($Section in $Sections) {
    $HeroSource = Get-ChildItem -LiteralPath $HeroesSource -File |
      Where-Object { $_.BaseName -eq $Section.id -and $SupportedExtensions -contains $_.Extension.ToLowerInvariant() } |
      Select-Object -First 1

    if ($HeroSource) {
      $HeroDestination = Join-Path $ProjectRoot "src\images\heroes\$($Section.id).webp"

      Write-Host "Hero image: $($Section.title)"
      & magick $HeroSource.FullName -auto-orient -strip -resize "2400x1600^" -gravity center -extent "2400x1600" -quality 90 -define webp:method=6 $HeroDestination
      if ($LASTEXITCODE -ne 0) { throw "Could not create the hero image $($HeroSource.FullName)" }
    }
  }
}

$AllArchivePath = Join-Path $ArchivesDir "all-photos.zip"
New-ZipArchive -Destination $AllArchivePath -Items $AllZipItems

$Manifest = [ordered]@{
  generatedAt = [DateTime]::UtcNow.Ticks
  downloadAll = "/photos/downloads/all-photos.zip"
  sections = $ManifestSections
}

$Json = $Manifest | ConvertTo-Json -Depth 8
$PhotosJs = "// Generated automatically by scripts/build-photos.ps1`r`nwindow.WEDDING_GALLERY = $Json;`r`n"
$Utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($PhotosJsPath, $PhotosJs.Replace("`r`n", "`n"), $Utf8WithoutBom)

Write-Host "`nDone." -ForegroundColor Green
Write-Host "Site photos: $PhotosRoot"
Write-Host "All photos archive: $AllArchivePath"
Write-Host "Gallery manifest: $PhotosJsPath"
