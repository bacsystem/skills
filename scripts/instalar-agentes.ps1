# Enlaza la carpeta agents\ de este repositorio a las carpetas globales de agentes:
# - Claude Code: %USERPROFILE%\.claude\agents
# - Gemini / Antigravity: %USERPROFILE%\.gemini\agents
# Usa junctions: no requiere permisos de administrador ni el modo desarrollador.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File scripts\instalar-agentes.ps1 [-Target all|claude|gemini]
#   powershell -ExecutionPolicy Bypass -File scripts\instalar-agentes.ps1 [-Destino <ruta>]
#
# Si el destino ya existe y no es este enlace, se renombra a <destino>.respaldo-<fecha>
# antes de enlazar: nada se borra.
param(
    [ValidateSet('all', 'claude', 'gemini')]
    [string]$Target = 'all',
    [string]$Destino = ''
)
$ErrorActionPreference = 'Stop'

$origen = Join-Path (Split-Path -Parent $PSScriptRoot) 'agents'
if (-not (Test-Path -LiteralPath $origen -PathType Container)) {
    throw "No se encontró $origen"
}
$origen = (Resolve-Path -LiteralPath $origen).Path.TrimEnd('\')

function Enlazar-Carpeta {
    param(
        [string]$RutaDestino,
        [string]$Nombre
    )
    $RutaDestino = $RutaDestino.TrimEnd('\', '/')
    $item = Get-Item -LiteralPath $RutaDestino -Force -ErrorAction SilentlyContinue
    if ($item) {
        $esEnlace = $item.LinkType -in @('Junction', 'SymbolicLink')
        if ($esEnlace -and "$($item.Target)".TrimEnd('\') -eq $origen) {
            Write-Output "Ya enlazado ($Nombre): $RutaDestino -> $origen"
            return
        }
        $respaldo = "$RutaDestino.respaldo-$(Get-Date -Format 'yyyyMMddHHmmss')"
        Rename-Item -LiteralPath $RutaDestino -NewName (Split-Path -Leaf $respaldo)
        Write-Output "Respaldado ($Nombre): $RutaDestino -> $respaldo"
    }

    $padre = Split-Path -Parent $RutaDestino
    if (-not (Test-Path -LiteralPath $padre)) {
        New-Item -ItemType Directory -Path $padre | Out-Null
    }
    New-Item -ItemType Junction -Path $RutaDestino -Target $origen | Out-Null
    Write-Output "Enlazado ($Nombre): $RutaDestino -> $origen"
}

if ($Destino -ne '') {
    Enlazar-Carpeta -RutaDestino $Destino -Nombre 'Personalizado'
} elseif ($Target -eq 'claude') {
    Enlazar-Carpeta -RutaDestino (Join-Path $HOME '.claude\agents') -Nombre 'Claude Code'
    Write-Output 'Abre una sesión nueva de Claude Code para cargar los agentes.'
} elseif ($Target -eq 'gemini') {
    Enlazar-Carpeta -RutaDestino (Join-Path $HOME '.gemini\agents') -Nombre 'Gemini / Antigravity'
    Write-Output 'Abre una sesión nueva de Gemini CLI o Antigravity para cargar los agentes.'
} else {
    Enlazar-Carpeta -RutaDestino (Join-Path $HOME '.claude\agents') -Nombre 'Claude Code'
    Enlazar-Carpeta -RutaDestino (Join-Path $HOME '.gemini\agents') -Nombre 'Gemini / Antigravity'
    Write-Output 'Abre una sesión nueva de Claude Code o Gemini/Antigravity para cargar los agentes.'
}
