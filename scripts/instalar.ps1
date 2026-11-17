# Instala tanto agentes como skills de este repositorio:
# - Claude Code: %USERPROFILE%\.claude\agents y %USERPROFILE%\.claude\skills\
# - Gemini / Antigravity: %USERPROFILE%\.gemini\agents y %USERPROFILE%\.gemini\skills\
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File scripts\instalar.ps1 [-Target all|claude|gemini]
param(
    [ValidateSet('all', 'claude', 'gemini')]
    [string]$Target = 'all'
)
$ErrorActionPreference = 'Stop'

Write-Output '=== Instalando agentes ==='
& (Join-Path $PSScriptRoot 'instalar-agentes.ps1') -Target $Target

Write-Output ''
Write-Output '=== Instalando skills ==='
& (Join-Path $PSScriptRoot 'instalar-skills.ps1') -Target $Target

Write-Output ''
Write-Output '¡Instalación completada exitosamente!'
