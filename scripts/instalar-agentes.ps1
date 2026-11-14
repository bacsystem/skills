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
# Sin barras finales: con "dir\" el respaldo tomaría un nombre equivocado.
$Destino = $Destino.TrimEnd('\', '/')

# Get-Item y no Test-Path: Test-Path da falso con un enlace roto, que sí existe.
$item = Get-Item -LiteralPath $Destino -Force -ErrorAction SilentlyContinue
if ($item) {
    $esEnlace = $item.LinkType -in @('Junction', 'SymbolicLink')
    if ($esEnlace -and "$($item.Target)".TrimEnd('\') -eq $origen) {
        Write-Output "Ya enlazado: $Destino -> $origen"
        exit 0
    }
    # Carpeta o enlace a otra parte: se renombra. Rename-Item sobre una junction
    # renombra el enlace, no el contenido de la carpeta a la que apunta.
    $respaldo = "$Destino.respaldo-$(Get-Date -Format 'yyyyMMddHHmmss')"
    Rename-Item -LiteralPath $Destino -NewName (Split-Path -Leaf $respaldo)
    Write-Output "Respaldado: $Destino -> $respaldo"
}

$padre = Split-Path -Parent $Destino
if (-not (Test-Path -LiteralPath $padre)) {
    New-Item -ItemType Directory -Path $padre | Out-Null
}
New-Item -ItemType Junction -Path $Destino -Target $origen | Out-Null
Write-Output "Enlazado: $Destino -> $origen"
Write-Output 'Abre una sesión nueva de Claude Code para cargar los agentes.'
