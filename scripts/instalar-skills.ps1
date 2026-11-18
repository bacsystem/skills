# Enlaza las skills de este repositorio a las carpetas globales de skills:
# - Claude Code: %USERPROFILE%\.claude\skills\<nombre-skill>
# - Gemini / Antigravity: %USERPROFILE%\.gemini\skills\<nombre-skill>
# Usa junctions: no requiere permisos de administrador ni el modo desarrollador.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File scripts\instalar-skills.ps1 [-Target all|claude|gemini]
#   powershell -ExecutionPolicy Bypass -File scripts\instalar-skills.ps1 [-Destino <ruta>]
#
# Si el destino de una skill ya existe:
# - un enlace (junction o symlink) a otra ruta se reemplaza (borrar un enlace no pierde nada);
# - una carpeta o archivo real se mueve a <carpeta_destino>-respaldo\<skill>-<fecha>,
#   fuera de la carpeta de skills: un respaldo dentro de ella se cargaría como
#   una skill más con el mismo nombre.
param(
    [ValidateSet('all', 'claude', 'gemini')]
    [string]$Target = 'all',
    [string]$Destino = ''
)
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

function Enlazar-SkillsEn {
    param(
        [string]$BaseDestino,
        [string]$NombreEntorno
    )
    $BaseDestino = $BaseDestino.TrimEnd('\', '/')
    if (-not (Test-Path -LiteralPath $BaseDestino)) {
        New-Item -ItemType Directory -Path $BaseDestino | Out-Null
    }

    if (Test-Path -LiteralPath (Join-Path $BaseDestino '.git')) {
        Write-Warning "($NombreEntorno) $BaseDestino es un clon de git. Un pull o checkout ahí puede devolver copias viejas de las skills que pisen estos enlaces. Conviértela en una carpeta normal (saca .git y los archivos del repo)."
    }

    $candidatos = Get-ChildItem -LiteralPath $repoRoot -Directory
    foreach ($dir in $candidatos) {
        $skillFile = Join-Path $dir.FullName 'SKILL.md'
        if (Test-Path -LiteralPath $skillFile -PathType Leaf) {
            $skillName = $dir.Name
            $destino = Join-Path $BaseDestino $skillName
            $origen = $dir.FullName.TrimEnd('\')

            $item = Get-Item -LiteralPath $destino -Force -ErrorAction SilentlyContinue
            if ($item) {
                $esEnlace = $item.LinkType -in @('Junction', 'SymbolicLink')
                if ($esEnlace -and "$($item.Target)".TrimEnd('\') -eq $origen) {
                    Write-Output "Ya enlazado ($NombreEntorno): $destino -> $origen"
                    continue
                }
                if ($esEnlace) {
                    # Quitar el enlace no toca la carpeta a la que apunta.
                    $item.Delete()
                    Write-Output "Reemplazado ($NombreEntorno): enlace anterior $destino"
                } else {
                    $carpetaRespaldo = "$BaseDestino-respaldo"
                    if (-not (Test-Path -LiteralPath $carpetaRespaldo)) {
                        New-Item -ItemType Directory -Path $carpetaRespaldo | Out-Null
                    }
                    $respaldo = Join-Path $carpetaRespaldo "$skillName-$(Get-Date -Format 'yyyyMMddHHmmss')"
                    Move-Item -LiteralPath $destino -Destination $respaldo
                    Write-Output "Respaldado ($NombreEntorno): $destino -> $respaldo"
                }
            }

            New-Item -ItemType Junction -Path $destino -Target $origen | Out-Null
            Write-Output "Enlazado ($NombreEntorno): $destino -> $origen"
        }
    }
}

if ($Destino -ne '') {
    Enlazar-SkillsEn -BaseDestino $Destino -NombreEntorno 'Personalizado'
} elseif ($Target -eq 'claude') {
    Enlazar-SkillsEn -BaseDestino (Join-Path $HOME '.claude\skills') -NombreEntorno 'Claude Code'
    Write-Output 'Skills disponibles en Claude Code. Abre una sesión nueva para usarlas.'
} elseif ($Target -eq 'gemini') {
    Enlazar-SkillsEn -BaseDestino (Join-Path $HOME '.gemini\skills') -NombreEntorno 'Gemini / Antigravity'
    Write-Output 'Skills disponibles en Gemini CLI / Antigravity. Abre una sesión nueva para usarlas.'
} else {
    Enlazar-SkillsEn -BaseDestino (Join-Path $HOME '.claude\skills') -NombreEntorno 'Claude Code'
    Enlazar-SkillsEn -BaseDestino (Join-Path $HOME '.gemini\skills') -NombreEntorno 'Gemini / Antigravity'
    Write-Output 'Skills disponibles en Claude Code y Gemini / Antigravity. Abre una sesión nueva para usarlas.'
}
