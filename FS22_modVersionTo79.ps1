# Définir le chemin à analyser
$chemin = "C:\Users\Fahim\Documents\My Games\FarmingSimulator2022\mods"

# Parcourir chaque fichier .zip dans le dossier
Get-ChildItem -Path $chemin -Filter *.zip | ForEach-Object {
    $zipPath = $_.FullName
    $tempDir = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    # Extraire le fichier modDesc.xml
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempDir)

    $modDescPath = Join-Path $tempDir "modDesc.xml"
    if (Test-Path $modDescPath) {
        $xml = [xml](Get-Content $modDescPath)
        
        if ($xml.modDesc.descversion -eq "80") {
            $xml.modDesc.descversion = "79"
            $xml.Save($modDescPath)
            Write-Host "Version modifiée dans "$_.FullName "("$xml.modDesc.title.en")"

            # Mettre à jour le zip
            Remove-Item $zipPath
            [System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $zipPath)
            #Write-Host "Version modifiée dans $zipPath"
        }
    }
   Remove-Item -Path $tempDir -Recurse -Force
}