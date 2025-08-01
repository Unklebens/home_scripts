 $startTime = Get-Date
# Définir le chemin à analyser
$chemin = "C:\Users\Fahim\Documents\My Games\FarmingSimulator2022\mods"

Add-Type -AssemblyName System.IO.Compression.FileSystem

# Parcourir chaque fichier .zip dans le dossier
Get-ChildItem -Path $chemin -Filter *.zip | ForEach-Object {
    $zipPath = $_.FullName
    $tempDir = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    $modDescTempPath = Join-Path $tempDir "modDesc.xml"

    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $entry = $zip.Entries | Where-Object { $_.FullName -ieq "modDesc.xml" }
    
    if ($entry) {
        $entry.ExtractToFile($modDescTempPath)
        $zip.Dispose()

        $xml = [xml](Get-Content $modDescTempPath)

        if ($xml.modDesc.descversion -eq "80") {
            $xml.modDesc.descversion = "79"
            $xml.Save($modDescTempPath)
            Write-Host "Version modifiée dans $zipPath ($($xml.modDesc.title.en))" -ForegroundColor Yellow

            # Supprimer l'ancien fichier modDesc.xml du zip
            $tempZipDir = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
            New-Item -ItemType Directory -Path $tempZipDir | Out-Null
            [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempZipDir)

            Copy-Item -Path $modDescTempPath -Destination (Join-Path $tempZipDir "modDesc.xml") -Force

            Remove-Item $zipPath
            [System.IO.Compression.ZipFile]::CreateFromDirectory($tempZipDir, $zipPath)

            Remove-Item -Path $tempZipDir -Recurse -Force
        } else {
            $zip.Dispose()
        }
    }

    Remove-Item -Path $tempDir -Recurse -Force
}
$endTime = Get-Date
$duration = $endTime - $startTime
Write-Host "Temps d'exécution total : $($duration.TotalSeconds) secondes"
Start-Sleep -Seconds 5
Write-Host "Appuyez sur une touche pour quitter..."