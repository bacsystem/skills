# Enlaza la carpeta agents\ de este repositorio a %USERPROFILE%\.claude\agents (Windows).
# Usa una junction: no requiere permisos de administrador ni el modo desarrollador.
#
# Uso: powershell -ExecutionPolicy Bypass -File scripts\instalar-agentes.ps1 [-Destino <ruta>]
# Se puede ejecutar desde cualquier carpeta. Si el destino ya existe y no es este
# enlace, se renombra a <destino>.respaldo-<fecha> antes de enlazar: nada se borra.
param(
    [string]$Destino = (Join-Path $HOME '.claude\agents')
)
$ErrorActionPreference = 'Stop'

$origen = Join-Path (Split-Path -Parent $PSScriptRoot) 'agents'
if (-not (Test-Path -LiteralPath $origen -PathType Container)) {
    throw "No se encontró $origen"
}
$origen = (Resolve-Path -LiteralPath $origen).Path.TrimEnd('\')

if (Test-Path -LiteralPath $Destino) {
    $item = Get-Item -LiteralPath $Destino -Force
    if ($item.LinkType -in @('Junction', 'SymbolicLink')) {
        $actual = "$($item.Target)".TrimEnd('\')
        if ($actual -eq $origen) {
            Write-Output "Ya enlazado: $Destino -> $origen"
            exit 0
        }
        # Borra solo el enlace, nunca el contenido de la carpeta a la que apunta.
        [System.IO.Directory]::Delete($Destino, $false)
    } else {
        $respaldo = "$Destino.respaldo-$(Get-Date -Format 'yyyyMMddHHmmss')"
        Rename-Item -LiteralPath $Destino -NewName (Split-Path -Leaf $respaldo)
        Write-Output "Respaldado: $Destino -> $respaldo"
    }
}

$padre = Split-Path -Parent $Destino
if (-not (Test-Path -LiteralPath $padre)) {
    New-Item -ItemType Directory -Path $padre | Out-Null
}
New-Item -ItemType Junction -Path $Destino -Target $origen | Out-Null
Write-Output "Enlazado: $Destino -> $origen"
Write-Output 'Abre una sesión nueva de Claude Code para cargar los agentes.'
