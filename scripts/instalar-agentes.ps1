# Enlaza o instala la carpeta agents\ de este repositorio en las carpetas globales de agentes:
# - Claude Code: %USERPROFILE%\.claude\agents (junction directo)
# - Gemini / Antigravity: %USERPROFILE%\.gemini\config\agents\<nombre>\agent.md (frontmatter adaptado)
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

function Instalar-Gemini {
    param(
        [string]$BaseDestino,
        [string]$Nombre
    )
    $BaseDestino = $BaseDestino.TrimEnd('\', '/')
    $item = Get-Item -LiteralPath $BaseDestino -Force -ErrorAction SilentlyContinue
    if ($item -and (($item.LinkType -in @('Junction', 'SymbolicLink')) -or (-not $item.PSIsContainer))) {
        $respaldo = "$BaseDestino.respaldo-$(Get-Date -Format 'yyyyMMddHHmmss')"
        Rename-Item -LiteralPath $BaseDestino -NewName (Split-Path -Leaf $respaldo)
        Write-Output "Respaldado ($Nombre): $BaseDestino -> $respaldo"
    }

    if (-not (Test-Path -LiteralPath $BaseDestino)) {
        New-Item -ItemType Directory -Path $BaseDestino | Out-Null
    }

    $count = 0
    $archivos = Get-ChildItem -LiteralPath $origen -Filter '*.md' -File
    foreach ($archivo in $archivos) {
        if ($archivo.Name -eq 'README.md') { continue }

        $agentName = $archivo.BaseName
        $destDir = Join-Path $BaseDestino $agentName
        $destFile = Join-Path $destDir 'agent.md'
        if (-not (Test-Path -LiteralPath $destDir)) {
            New-Item -ItemType Directory -Path $destDir | Out-Null
        }

        $lineas = Get-Content -LiteralPath $archivo.FullName -Encoding UTF8
        $salida = New-Object System.Collections.Generic.List[string]
        $fm = 0
        foreach ($linea in $lineas) {
            if ($fm -lt 2 -and $linea -match '^---\s*$') {
                $fm++
                $salida.Add($linea)
                continue
            }
            if ($fm -eq 1) {
                if ($linea -match '^effort:\s*') { continue }
                if ($linea -match '^tools:\s*(.*)$') {
                    $rawTools = $Matches[1] -split ',\s*'
                    $mapped = New-Object System.Collections.Generic.List[string]
                    foreach ($t in $rawTools) {
                        $t = $t.Trim()
                        $targets = switch ($t) {
                            { $_ -in @('Read', 'Grep', 'Glob') } { @('read_file') }
                            { $_ -in @('Edit', 'MultiEdit') } { @('edit_file') }
                            'Write' { @('write_file') }
                            'Bash' { @('run_command', 'manage_task') }
                            { $_ -in @('WebSearch', 'WebFetch') } { @('search_web') }
                            'SendMessage' { @('send_message') }
                            default { @() }
                        }
                        foreach ($m in $targets) {
                            if (-not $mapped.Contains($m)) { $mapped.Add($m) }
                        }
                    }
                    if ($mapped.Count -gt 0) {
                        $salida.Add("tools: [$($mapped -join ', ')]")
                    }
                    continue
                }
                if ($linea -match '^model:\s*opus\s*$') { $salida.Add('model: pro'); continue }
                if ($linea -match '^model:\s*sonnet\s*$') { $salida.Add('model: flash'); continue }
                if ($linea -match '^model:\s*haiku\s*$') { $salida.Add('model: flash_lite'); continue }
            }
            $salida.Add($linea)
        }

        [System.IO.File]::WriteAllLines($destFile, $salida, [System.Text.UTF8Encoding]::new($false))
        $count++
    }

    Write-Output "Instalados $count agentes ($Nombre): $BaseDestino\<nombre>\agent.md"
}

if ($Destino -ne '') {
    Enlazar-Carpeta -RutaDestino $Destino -Nombre 'Personalizado'
} elseif ($Target -eq 'claude') {
    Enlazar-Carpeta -RutaDestino (Join-Path $HOME '.claude\agents') -Nombre 'Claude Code'
    Write-Output 'Abre una sesión nueva de Claude Code para cargar los agentes.'
} elseif ($Target -eq 'gemini') {
    Instalar-Gemini -BaseDestino (Join-Path $HOME '.gemini\config\agents') -Nombre 'Gemini / Antigravity'
    Write-Output 'Abre una sesión nueva de Gemini CLI o Antigravity para cargar los agentes.'
} else {
    Enlazar-Carpeta -RutaDestino (Join-Path $HOME '.claude\agents') -Nombre 'Claude Code'
    Instalar-Gemini -BaseDestino (Join-Path $HOME '.gemini\config\agents') -Nombre 'Gemini / Antigravity'
    Write-Output 'Abre una sesión nueva de Claude Code o Gemini/Antigravity para cargar los agentes.'
}
