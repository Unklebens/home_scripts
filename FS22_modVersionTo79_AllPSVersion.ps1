# Description: Script PowerShell pour modifier la version de description de modDesc.xml de 80 à 79 dans les mods de Farming Simulator 22.
Write-Host "Analyse des mods en cours" -ForegroundColor Cyan
$startTime = Get-Date
Get-ModFolder 
Add-Type -AssemblyName System.IO.Compression.FileSystem

$psMajor = $PSVersionTable.PSVersion.Major

Get-ChildItem -Path $chemin -Filter *.zip | ForEach-Object {
    $zipPath = $_.FullName
    $tempDir = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    $modDescTempPath = Join-Path $tempDir "modDesc.xml"

    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $entry = $zip.Entries | Where-Object { $_.FullName -ieq "modDesc.xml" }

    if ($entry) {
        if ($psMajor -ge 7) {
            # Méthode PowerShell 7+
            $entry.ExtractToFile($modDescTempPath)
        } else {
            # Méthode PowerShell 5.1
            $stream = $entry.Open()
            $fileStream = [System.IO.File]::Create($modDescTempPath)
            $stream.CopyTo($fileStream)
            $stream.Close()
            $fileStream.Close()
        }
        $zip.Dispose()

        $xml = [xml](Get-Content $modDescTempPath)

        if ($xml.modDesc.descversion -eq "80") {
            $xml.modDesc.descversion = "79"
            $xml.Save($modDescTempPath)
            Write-Host "Version modifiée dans ($($xml.modDesc.title.en))" -ForegroundColor Yellow

            $tempZipDir = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
            New-Item -ItemType Directory -Path $tempZipDir | Out-Null
            [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempZipDir)

            Copy-Item -Path $modDescTempPath -Destination (Join-Path $tempZipDir "modDesc.xml") -Force

            Remove-Item $zipPath
            [System.IO.Compression.ZipFile]::CreateFromDirectory($tempZipDir, $zipPath)

            Remove-Item -Path $tempZipDir -Recurse -Force
        }
    }

    Remove-Item -Path $tempDir -Recurse -Force
}
$endTime = Get-Date
$duration = $endTime - $startTime
Write-Host "Temps d'exécution total : $($duration.TotalSeconds) secondes" -ForegroundColor Green
#Start-Sleep -Seconds 5


function Get-ModFolder {
    $modfolder = [xml](Get-Content "C:\Users\$env:USERNAME\Documents\My Games\FarmingSimulator2022\gameSettings.xml")

    if ($modfolder.gameSettings.modsDirectoryOverride.active -eq "false") {
        <# Action to perform if the condition is true #>
        $chemin= "C:\Users\$env:USERNAME\Documents\My Games\FarmingSimulator2022\mods"
    } else {
        <# Action to perform if the condition is false #>
        $chemin = $modfolder.gameSettings.modsDirectoryOverride.directory
    }
    Write-Host "Chemin des mods : $chemin" -ForegroundColor Cyan
}