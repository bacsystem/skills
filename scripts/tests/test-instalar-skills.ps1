# Prueba scripts\instalar-skills.ps1 con junctions en una carpeta temporal
# (nunca toca ~\.claude ni ~\.gemini). Sirve en Windows PowerShell 5.1 y en pwsh.
# Uso: powershell -ExecutionPolicy Bypass -File scripts\tests\test-instalar-skills.ps1
$ErrorActionPreference = 'Stop'

$script = Join-Path (Split-Path -Parent $PSScriptRoot) 'instalar-skills.ps1'
$repo = Split-Path -Parent (Split-Path -Parent $script)
$skill = (Get-ChildItem -LiteralPath $repo -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') } | Select-Object -First 1).Name
$T = Join-Path ([IO.Path]::GetTempPath()) ("skills-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $T | Out-Null

function Check([string]$desc, [bool]$cond, [string]$detalle = '') {
    if (-not $cond) { Write-Host "salida:`n$detalle"; Write-Error "FALLO: $desc"; exit 1 }
    Write-Host "ok - $desc"
}
# El instalador corre en un proceso hijo (el mismo PowerShell que corre el test) con el perfil
# apuntando a $T\home: aunque ignorara -Destino, no podría tocar ~\.claude ni ~\.gemini.
$perfil = Join-Path $T 'home'; New-Item -ItemType Directory -Path $perfil | Out-Null
$env:USERPROFILE = $perfil; $env:HOME = $perfil; $env:HOMEDRIVE = (Split-Path -Qualifier $perfil); $env:HOMEPATH = $perfil.Substring($env:HOMEDRIVE.Length)
$ps = (Get-Process -Id $PID).Path
function Run([string]$dest) {
    $eap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $out = & $ps -NoProfile -ExecutionPolicy Bypass -File $script -Destino $dest 2>&1 | Out-String
    $code = $LASTEXITCODE; $ErrorActionPreference = $eap
    if ($code -ne 0) { Write-Host $out; Write-Error "FALLO: el instalador salió con código $code"; exit 1 }
    $out
}
function ApuntaAlRepo([string]$p) {
    $i = Get-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
    return [bool]($i -and $i.LinkType -eq 'Junction' -and ("$($i.Target)".TrimEnd('\') -eq (Join-Path $repo $skill)))
}
function Existe([string]$p) { Test-Path -LiteralPath $p }
function NewLink([string]$link, [string]$target) { New-Item -ItemType Junction -Path $link -Target $target | Out-Null }

try {
    $d = Join-Path $T 'skills'; $r = "$d-respaldo"

    # 1 y 8: enlaza, y la segunda corrida no cambia nada
    Run $d | Out-Null
    Check 'enlaza la skill al repo' (ApuntaAlRepo "$d\$skill")
    $out = Run $d
    Check 'segunda corrida: Ya enlazado' ($out -match "Ya enlazado.*$skill")
    Check 'segunda corrida: sin respaldo' (-not (Existe $r))

    # 2: un enlace a otra ruta se reemplaza y su destino queda intacto
    $otra = Join-Path $T 'otra'; New-Item -ItemType Directory -Path $otra | Out-Null
    Set-Content -LiteralPath "$otra\dato" -Value 'x'
    (Get-Item -LiteralPath "$d\$skill" -Force).Delete(); NewLink "$d\$skill" $otra
    Run $d | Out-Null
    Check 'enlace ajeno reemplazado' (ApuntaAlRepo "$d\$skill")
    Check 'carpeta del enlace ajeno intacta' (Existe "$otra\dato")
    Check 'enlace ajeno sin respaldo' (-not (Existe $r))

    # 3: carpeta real -> <destino>-respaldo\<skill>-<fecha>
    (Get-Item -LiteralPath "$d\$skill" -Force).Delete()
    New-Item -ItemType Directory -Path "$d\$skill" | Out-Null
    Set-Content -LiteralPath "$d\$skill\mio" -Value 'y'
    Run $d | Out-Null
    Check 'carpeta real enlazada' (ApuntaAlRepo "$d\$skill")
    $resp = @(Get-ChildItem -LiteralPath $r -Directory -Filter "$skill-*")
    Check 'carpeta real respaldada' (($resp.Count -eq 1) -and (Existe "$($resp[0].FullName)\mio"))

    # 4: <skill>.respaldo-* dentro del destino (carpeta real y enlace) salen
    New-Item -ItemType Directory -Path "$d\$skill.respaldo-1" | Out-Null
    NewLink "$d\$skill.respaldo-2" $otra
    New-Item -ItemType Directory -Path "$T\nada-3" | Out-Null
    NewLink "$d\$skill.respaldo-3" "$T\nada-3"
    Remove-Item -LiteralPath "$T\nada-3"   # junction rota
    Run $d | Out-Null
    Check 'respaldo viejo (carpeta) movido' (Existe "$r\$skill.respaldo-1")
    Check 'respaldo viejo roto movido' (Existe "$r\$skill.respaldo-3")
    Check 'respaldo viejo (enlace) movido' ((Get-Item -LiteralPath "$r\$skill.respaldo-2" -Force).LinkType -eq 'Junction')
    Check 'nada .respaldo-* dentro del destino' (@(Get-ChildItem -LiteralPath $d -Force -Filter '*.respaldo-*').Count -eq 0)

    # 5: destino relativo "." -> el respaldo cae al lado, no dentro
    $rel = Join-Path $T 'rel'; New-Item -ItemType Directory -Path "$rel\$skill" | Out-Null
    Push-Location $rel
    try { Run '.' | Out-Null } finally { Pop-Location }
    Check "destino '.' : respaldo fuera" (Existe "$rel-respaldo")
    Check "destino '.' : nada dentro" (@(Get-ChildItem -LiteralPath $rel -Force -Filter '*respaldo*').Count -eq 0)

    # 6: destino con .git -> aviso
    New-Item -ItemType Directory -Path "$T\clon\.git" -Force | Out-Null
    $out = Run "$T\clon"
    Check 'aviso si el destino es un clon git' (($out -replace '\s+', ' ') -match 'clon de git') $out

    # 7: junction rota en el destino de la skill se reemplaza
    $rotoDir = Join-Path $T 'gone'; New-Item -ItemType Directory -Path $rotoDir | Out-Null
    (Get-Item -LiteralPath "$d\$skill" -Force).Delete(); NewLink "$d\$skill" $rotoDir
    Remove-Item -LiteralPath $rotoDir
    Run $d | Out-Null
    Check 'junction rota reemplazada' (ApuntaAlRepo "$d\$skill")

    # 9: -Destino con \ final
    New-Item -ItemType Directory -Path "$T\barra" | Out-Null
    Run "$T\barra\" | Out-Null
    Check 'destino con \ final enlaza' (ApuntaAlRepo "$T\barra\$skill")

    Check 'perfil aislado: el instalador no escribió fuera de -Destino' (-not (Existe "$perfil\.claude"))
    Write-Host 'OK: instalar-skills.ps1 pasa todas las pruebas (reglas 1-6, 8)'
} finally {
    Set-Location $env:TEMP 2>$null
    Remove-Item -LiteralPath $T -Recurse -Force -ErrorAction SilentlyContinue
}
