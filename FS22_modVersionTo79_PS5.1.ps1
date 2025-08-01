 $startTime = Get-Date
# Définir le chemin à analyser
$chemin = "C:\Users\Fahim\Documents\My Games\FarmingSimulator2022\mods"
# charger la libraire dotnt pour les zip
Add-Type -AssemblyName System.IO.Compression.FileSystem

Get-ChildItem -Path $chemin -Filter *.zip | ForEach-Object {
    $zipPath = $_.FullName
    $tempDir = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    $modDescTempPath = Join-Path $tempDir "modDesc.xml"

    # Ouvrir le fichier zip
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)

    # Trouver l’entrée modDesc.xml (insensible à la casse)
    $entry = $zip.Entries | Where-Object { $_.FullName -ieq "modDesc.xml" }

    if ($entry) {
        # Extraire manuellement via Stream
        $stream = $entry.Open()
        $fileStream = [System.IO.File]::Create($modDescTempPath)
        $stream.CopyTo($fileStream)
        $stream.Close()
        $fileStream.Close()
        $zip.Dispose()

        # Charger et modifier le XML
        $xml = [xml](Get-Content $modDescTempPath)
        Write-Host "Analyse de $($xml.modDesc.title.en)"
        if ($xml.modDesc.descversion -eq "80") {
            $xml.modDesc.descversion = "79"
            $xml.Save($modDescTempPath)
            Write-Host "Version modifiée dans $zipPath ($($xml.modDesc.title.en))" -ForegroundColor Yellow

            # Remplacer le fichier dans le zip
            $tempZipDir = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
            New-Item -ItemType Directory -Path $tempZipDir | Out-Null
            [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempZipDir)

            # Copier le fichier modifié
            Copy-Item -Path $modDescTempPath -Destination (Join-Path $tempZipDir "modDesc.xml") -Force

            # Recréer le zip
            Remove-Item $zipPath
            [System.IO.Compression.ZipFile]::CreateFromDirectory($tempZipDir, $zipPath)

            Remove-Item -Path $tempZipDir -Recurse -Force
        }
    }

    Remove-Item -Path $tempDir -Recurse -Force
}
$endTime = Get-Date
$duration = $endTime - $startTime
Write-Host "Temps d'exécution total : $($duration.TotalSeconds) secondes"
Start-Sleep -Seconds 5
Write-Host "Appuyez sur une touche pour quitter..."