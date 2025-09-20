<#
.SYNOPSIS
DST Mod ����ű�: ����ο�����

.PARAMETER action
ָ������: import | deploy
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("import","deploy")]
    [string]$action
)

# ·������
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$steamappsDir = "C:\Program Files (x86)\Steam\steamapps"
$dstDir = Join-Path $steamappsDir "common\Don't Starve Together"
$modTargetDir = Join-Path $dstDir "mods\dst-solo-townportal"
$officialScriptsZip = Join-Path $dstDir "data\databundles\scripts.zip"
$workshopDir = Join-Path $steamappsDir "workshop\content\322330"

function Copy-Workshop {
    $dest = Join-Path $projectDir ".322330"
    if (-Not (Test-Path $dest)) {
        New-Item -ItemType Directory -Path $dest | Out-Null
    } else {
        Get-ChildItem -Path $dest | Remove-Item -Recurse -Force
    }
    Write-Host "�����Ѱ�װ�Ĵ��⹤�� mod �� $dest"
    Copy-Item -Path $workshopDir\* -Destination $dest -Recurse -Force
}

function Extract-OfficialScripts {
    $dest = Join-Path $projectDir ".scripts"
    $temp = Join-Path $projectDir ".scripts_temp"

    foreach ($d in @($dest, $temp)) {
        if (Test-Path $d) { Remove-Item -Path $d -Recurse -Force }
        New-Item -ItemType Directory -Path $d | Out-Null
    }

    Write-Host "��ѹ�ٷ��ű��� $dest"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($officialScriptsZip, $temp)

    $srcScripts = Join-Path $temp "scripts"
    Get-ChildItem -Path $srcScripts -Recurse | ForEach-Object {
        $targetPath = $_.FullName.Replace($srcScripts, $dest)
        $targetDir = Split-Path $targetPath -Parent
        if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
        if (-not $_.PSIsContainer) { Copy-Item $_.FullName $targetPath -Force }
    }

    Remove-Item -Path $temp -Recurse -Force
}

function Deploy-Mod {
    Write-Host "���� mod �� $modTargetDir"
    if (-Not (Test-Path $modTargetDir)) {
        New-Item -ItemType Directory -Path $modTargetDir | Out-Null
    } else {
        Get-ChildItem -Path $modTargetDir | Remove-Item -Recurse -Force
    }
    $filesToCopy = @("modinfo.lua","modmain.lua")
    foreach ($file in $filesToCopy) {
        $src = Join-Path $projectDir $file
        Copy-Item -Path $src -Destination $modTargetDir -Force
    }

    $scriptsSrc = Join-Path $projectDir "scripts"
    $scriptsDest = Join-Path $modTargetDir "scripts"
    Copy-Item -Path $scriptsSrc -Destination $modTargetDir -Recurse -Force
}

switch ($action) {
    "import" {
        Copy-Workshop
        Extract-OfficialScripts
    }
    "deploy" {
        Deploy-Mod
    }
}
