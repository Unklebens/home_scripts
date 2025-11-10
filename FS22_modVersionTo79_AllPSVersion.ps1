# Description: Script PowerShell pour modifier la version de description de modDesc.xml de 80 à 79 dans les mods de Farming Simulator 22.

$startTime = Get-Date
function Get-ModFolder {
    $modfolder = [xml](Get-Content "C:\Users\$env:USERNAME\Documents\My Games\FarmingSimulator2022\gameSettings.xml")
    if ($modfolder.gameSettings.modsDirectoryOverride.active -eq "false") {
        return "C:\Users\$env:USERNAME\Documents\My Games\FarmingSimulator2022\mods"
    } else {
        return $modfolder.gameSettings.modsDirectoryOverride.directory
    }
    
}

function Get-FSVersion {
    $result = Select-String -path "C:\Users\$env:USERNAME\Documents\My Games\FarmingSimulator2022\log.txt" -Pattern "ModDesc" | Select-Object -First 1
    if ($result) {
        return $result.Line.Split(":")[1].Trim()
    } else {
        return "79"
    }
}

# ...existing code...
$chemin = Get-ModFolder
Write-Host "Le dossier des mods est : $chemin" -ForegroundColor Cyan
$FSVersion = Get-FSVersion
Write-Host "Version de FS22 : $FSVersion" -ForegroundColor Cyan
Add-Type -AssemblyName System.IO.Compression.FileSystem
#$psMajor = $PSVersionTable.PSVersion.Major

Write-Host "Analyse des mods en cours" -ForegroundColor Cyan
Get-ChildItem -Path $chemin -Filter *.zip | ForEach-Object {
    $zipPath = $_.FullName

    try {
        $archive = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Update)
    } catch {
        Write-Host "Impossible d'ouvrir l'archive : $zipPath ($($_.Exception.Message))" -ForegroundColor Red
        return
    }

    try {
        # Cherche l'entrée modDesc.xml (peu importe le chemin interne)
        $entry = $archive.Entries | Where-Object { $_.Name -ieq "modDesc.xml" } | Select-Object -First 1

        if ($entry) {
            # Lire le contenu XML directement depuis l'entrée sans extraire toute l'archive
            $sr = New-Object System.IO.StreamReader ($entry.Open())
            $xmlContent = $sr.ReadToEnd()
            $sr.Close()

            $xml = [xml]$xmlContent

            if ($xml.modDesc -and $xml.modDesc.descversion -eq "80") {
                $xml.modDesc.descversion = $FSVersion

                # Supprime l'ancienne entrée puis crée une nouvelle entrée modDesc.xml et écrit le XML modifié
                $entry.Delete() 

                $newEntry = $archive.CreateEntry("modDesc.xml")
                $ws = $newEntry.Open()
                # XmlDocument.Save accepte un stream
                $xml.Save($ws)
                $ws.Close()

                Write-Host "Version mise a jour dans ($($xml.modDesc.title.en))" -ForegroundColor Yellow
            }
        }
    } finally {
        $archive.Dispose()
    }
}
$endTime = Get-Date
$duration = $endTime - $startTime
Write-Host "Temps d'execution total : $($duration.TotalSeconds) secondes" -ForegroundColor Green
# ...existing code...
#Start-Sleep -Seconds 5
