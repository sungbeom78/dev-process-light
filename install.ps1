# dev-process-light 설치 -- Windows PowerShell (5.1 이상)
#   powershell -ExecutionPolicy Bypass -File install.ps1 [프로젝트 폴더] [-Update <이름>|all] [-Keep <이름>|all]   (폴더를 생략하면 현재 폴더)
# install.sh 와 같은 일을 한다: 스킬 복사(light-* 7개 + 짝 데이터 설계 스킬 data-light), dev-notes 는 없을 때만,
# AGENTS.md 블록 넣기/갱신, CLAUDE.md 연결.
# 새 판 반영이 원칙, 다만 직접 고친 스킬 · 규칙 블록은 말없이 덮지 않는다 (소유자 원칙 2026-10-20 -- 어느 쪽을 둘지는 사용자가 정한다):
#   지난번에 설치한 그대로(또는 손대지 않은 예전 판)면 새 판으로, 직접 고친 것이면 손대지 않고 '물어볼 것'으로 알린 뒤 3 으로 끝난다.
#   -Update <이름|all> 새 판으로 (지금 것은 .light-backup\ 에) · -Keep <이름|all> 지금 것을 둔다. <이름> = 스킬 이름 또는 AGENTS.
#   지문 셈법은 install.sh · scripts/kit_hash.py 와 같다. 기록: .claude\skills\.light-kit
param([string]$Target = ".", [string[]]$Update = @(), [string[]]$Keep = @())
$ErrorActionPreference = "Stop"

$Kit = Join-Path $PSScriptRoot "kit"
$Begin = "<!-- dev-process-light:begin -->"
$End = "<!-- dev-process-light:end -->"
$Utf8 = New-Object System.Text.UTF8Encoding($false)   # BOM 없는 UTF-8

function Read-Utf8($p) { [System.IO.File]::ReadAllText($p, $Utf8) }
function Write-Utf8($p, $s) { [System.IO.File]::WriteAllText($p, $s, $Utf8) }

function Get-Sha256Hex($b) {
  if ($null -eq $b) { $b = New-Object byte[] 0 }        # 빈 파일
  $h = [System.Security.Cryptography.SHA256]::Create()
  try { return (-join ($h.ComputeHash([byte[]]$b) | ForEach-Object { $_.ToString("x2") })) } finally { $h.Dispose() }
}
function Remove-CR($b) {
  if ($null -eq $b -or $b.Length -eq 0) { return ,(New-Object byte[] 0) }
  if ([Array]::IndexOf([byte[]]$b, [byte]13) -lt 0) { return ,$b }
  $ms = New-Object System.IO.MemoryStream($b.Length)
  foreach ($x in $b) { if ($x -ne 13) { $ms.WriteByte($x) } }
  return ,$ms.ToArray()
}
function Get-TreeHash($dir) {
  $root = (Resolve-Path -LiteralPath $dir).Path.TrimEnd('\', '/')
  $rows = New-Object System.Collections.Generic.List[string]
  Get-ChildItem -LiteralPath $root -Recurse -File -Force | ForEach-Object {
    $rel = $_.FullName.Substring($root.Length).TrimStart('\', '/').Replace('\', '/')
    $leaf = $rel.Split('/')[-1]
    if ($leaf -like '.light-kit*' -or $leaf -like '*.pyc' -or ($rel.Split('/') -contains '__pycache__')) { return }
    $rows.Add("$rel`t$(Get-Sha256Hex (Remove-CR ([System.IO.File]::ReadAllBytes($_.FullName))))")
  }
  $arr = $rows.ToArray()
  [Array]::Sort($arr, [StringComparer]::Ordinal)
  $text = -join ($arr | ForEach-Object { $_ + "`n" })
  return (Get-Sha256Hex ([System.Text.Encoding]::UTF8.GetBytes($text))).Substring(0, 16)
}
function Get-BlockText($path) {
  if (-not (Test-Path -LiteralPath $path)) { return $null }
  $out = New-Object System.Text.StringBuilder
  $on = $false
  foreach ($line in ((Read-Utf8 $path).Replace("`r", "") -split "`n")) {
    if (-not $on -and $line.StartsWith($Begin)) { $on = $true }
    if ($on) {
      [void]$out.Append($line + "`n")
      if ($line.StartsWith($End)) { return $out.ToString() }
    }
  }
  return $null
}
function Get-BlockHash($path) {
  $t = Get-BlockText $path
  if ($null -eq $t) { return "" }
  return (Get-Sha256Hex ([System.Text.Encoding]::UTF8.GetBytes($t))).Substring(0, 16)
}
function Test-Wants($name, $list) { return ($list -contains "all") -or ($list -contains $name) }

if (-not (Test-Path (Join-Path $Kit "skills"))) { Write-Error "kit 폴더를 찾을 수 없습니다: $Kit" }
New-Item -ItemType Directory -Force -Path $Target | Out-Null
$Target = (Resolve-Path $Target).Path
Write-Host "dev-process-light 설치 -> $Target"

$StateFile = Join-Path $Target ".claude/skills/.light-kit"     # 경로는 / 로 (Windows 도 받는다 -- 다른 OS 의 pwsh 로도 시험)
$OldState = @()
if (Test-Path -LiteralPath $StateFile) { $OldState = (Read-Utf8 $StateFile).Replace("`r", "") -split "`n" }
$Hist = @()
if (Test-Path (Join-Path $Kit ".history")) { $Hist = (Read-Utf8 (Join-Path $Kit ".history")).Replace("`r", "") -split "`n" }
$NewState = New-Object System.Collections.Generic.List[string]
function Get-State($kind, $key) {
  foreach ($l in $OldState) { $p = $l -split ' '; if ($p.Count -ge 3 -and $p[0] -eq $kind -and $p[1] -eq $key) { return $p[2] } }
  return ""
}
function Add-State($kind, $key, $hash) { if ($hash) { $NewState.Add("$kind $key $hash") } }
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$Ask = New-Object System.Collections.Generic.List[string]
function Save-Backup($src, $rel) {
  $d = Join-Path $Target ".light-backup/$Stamp/$rel"
  New-Item -ItemType Directory -Force -Path (Split-Path $d) | Out-Null
  Copy-Item -Recurse -LiteralPath $src $d
  return ".light-backup/$Stamp/$rel"
}

# 1) 스킬
foreach ($hostDir in @(".claude/skills", ".agents/skills")) {
  $dest = Join-Path $Target $hostDir
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  $kitSkills = Get-ChildItem -Directory (Join-Path $Kit "skills")
  foreach ($s in $kitSkills) {
    $d = Join-Path $dest $s.Name
    $key = "$hostDir/$($s.Name)"
    $want = Get-TreeHash $s.FullName
    if (-not (Test-Path -LiteralPath $d)) { Copy-Item -Recurse $s.FullName $d; Add-State installed $key $want; continue }
    $have = Get-TreeHash $d
    if ($have -eq $want) { Add-State installed $key $want; continue }
    if ((Get-State installed $key) -eq $have -or ($Hist -contains "skill $($s.Name) $have")) {
      Remove-Item -Recurse -Force -LiteralPath $d; Copy-Item -Recurse $s.FullName $d; Add-State installed $key $want; continue
    }
    if (Test-Wants $s.Name $Update) {
      $b = Save-Backup $d $key
      Remove-Item -Recurse -Force -LiteralPath $d; Copy-Item -Recurse $s.FullName $d; Add-State installed $key $want
      Write-Host "  [OK] ${key}: 새 판으로 바꿈 (사용자 결정 -- 예전 것은 $b)"; continue
    }
    Add-State installed $key (Get-State installed $key)
    if ((Test-Wants $s.Name $Keep) -or (Get-State keep $key) -eq $have) {
      Add-State keep $key $have; Write-Host "  [유지] $key (직접 고친 것을 두기로 함 -- 사용자 결정)"; continue
    }
    $Ask.Add("  - $key (스킬 $($s.Name))")
  }
  Write-Host "  [OK] 스킬 $($kitSkills.Count)개 -> $hostDir"
}
$Lock = Join-Path $PSScriptRoot "data-light.lock.json"
if (Test-Path $Lock) {
  $pin = (Read-Utf8 $Lock) | ConvertFrom-Json
  Write-Host "  [OK] 짝 스킬 data-light $($pin.version) (data-expert-framework-light $($pin.commit.Substring(0, 7))) -- 저장할 데이터가 생기면 씁니다"
}
# 데이터 검사 장치(datalight.py hook install)가 프로젝트에 둔 도구 사본도 짝 버전으로 맞춘다
$Dlt = Join-Path $Kit "skills/data-light/scripts/datalight.py"
$DltDest = Join-Path $Target ".data-light/datalight.py"
# 줄바꿈(CRLF)만 다른 것은 같은 것으로 본다. 커밋 검사 훅 자체는 light-resume 이 `hook install` 로 다시 맞춘다
if ((Test-Path $DltDest) -and ((Read-Utf8 $DltDest).Replace("`r", "") -cne (Read-Utf8 $Dlt).Replace("`r", ""))) {
  Copy-Item -Force $Dlt $DltDest
  Write-Host "  [OK] .data-light\datalight.py 도 짝 버전으로 바꿈 -- light-resume 이 커밋 검사 훅도 다시 맞추고 저장합니다"
}

# 2) 기록 파일 (없을 때만)
$notes = Join-Path $Target "dev-notes"
New-Item -ItemType Directory -Force -Path $notes | Out-Null
Get-ChildItem (Join-Path $Kit "dev-notes") -Filter *.md | ForEach-Object {
  $d = Join-Path $notes $_.Name
  if (Test-Path $d) { Write-Host "  [유지] dev-notes\$($_.Name) (이미 있음)" }
  else { Copy-Item $_.FullName $d; Write-Host "  [OK] dev-notes\$($_.Name)" }
}

# 3) AGENTS.md 규칙 블록
$a = Join-Path $Target "AGENTS.md"
$block = Read-Utf8 (Join-Path $Kit "AGENTS.md")
$wantB = Get-BlockHash (Join-Path $Kit "AGENTS.md")
function Set-Block {
  $cur = Read-Utf8 $a
  $i = $cur.IndexOf($Begin); $j = $cur.IndexOf($End, [Math]::Max($i, 0))
  $after = $cur.Substring($j + $End.Length).TrimStart("`r", "`n")
  Write-Utf8 $a ($cur.Substring(0, $i) + $block.TrimEnd("`r", "`n") + "`n" + $after)
}
if (-not (Test-Path $a)) {
  Write-Utf8 $a $block; Add-State installed AGENTS $wantB; Write-Host "  [OK] AGENTS.md 만듦"
} else {
  $haveB = Get-BlockHash $a
  if (-not $haveB) {
    Write-Utf8 $a ((Read-Utf8 $a).TrimEnd("`r", "`n") + "`n`n" + $block); Add-State installed AGENTS $wantB; Write-Host "  [OK] AGENTS.md 끝에 규칙 블록 추가"
  } elseif ($haveB -eq $wantB) {
    Add-State installed AGENTS $wantB; Write-Host "  [유지] AGENTS.md 규칙 블록 (새 판과 같음)"
  } elseif ((Get-State installed AGENTS) -eq $haveB -or ($Hist -contains "block $haveB")) {
    Set-Block; Add-State installed AGENTS $wantB; Write-Host "  [OK] AGENTS.md 규칙 블록 갱신 (다른 내용은 그대로)"
  } elseif (Test-Wants "AGENTS" $Update) {
    $bd = Join-Path $Target ".light-backup/$Stamp"; New-Item -ItemType Directory -Force -Path $bd | Out-Null
    Write-Utf8 (Join-Path $bd "AGENTS.block.md") (Get-BlockText $a)
    Set-Block; Add-State installed AGENTS $wantB
    Write-Host "  [OK] AGENTS.md 규칙 블록: 새 판으로 바꿈 (사용자 결정 -- 예전 블록은 .light-backup/$Stamp/AGENTS.block.md)"
  } else {
    Add-State installed AGENTS (Get-State installed AGENTS)
    if ((Test-Wants "AGENTS" $Keep) -or (Get-State keep AGENTS) -eq $haveB) {
      Add-State keep AGENTS $haveB; Write-Host "  [유지] AGENTS.md 규칙 블록 (직접 고친 것을 두기로 함 -- 사용자 결정)"
    } else { $Ask.Add("  - AGENTS (AGENTS.md 의 규칙 블록)") }
  }
}

# 4) CLAUDE.md
$c = Join-Path $Target "CLAUDE.md"
if (-not (Test-Path $c)) { Write-Utf8 $c "@AGENTS.md`n"; Write-Host "  [OK] CLAUDE.md 만듦 (@AGENTS.md)" }
elseif (-not ((Read-Utf8 $c).Contains("@AGENTS.md"))) {
  Write-Utf8 $c ((Read-Utf8 $c).TrimEnd("`r", "`n") + "`n`n@AGENTS.md`n"); Write-Host "  [OK] CLAUDE.md 에 @AGENTS.md 추가"
} else { Write-Host "  [유지] CLAUDE.md" }

# 설치 기록 (다음 설치가 '직접 고쳤나'를 알아본다)
Write-Utf8 $StateFile ("# dev-process-light 설치 기록 -- 다음 설치가 직접 고친 것을 알아보려고 (지우면 다음 설치가 한 번 더 묻는다)`n" + (-join ($NewState | ForEach-Object { $_ + "`n" })))

# 쓸 수 있는 파이썬인지 실제로 실행해 본다 (Windows 의 가짜 python3 -- 스토어 안내 -- 는 여기서 걸러진다)
$Py = $null
foreach ($cmd in @("python", "py", "python3")) {
  if (Get-Command $cmd -ErrorAction SilentlyContinue) {
    try { & $cmd -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)" 2>$null | Out-Null; if ($LASTEXITCODE -eq 0) { $Py = $cmd; break } } catch {}
  }
}
if (-not $Py) {
  Write-Host "  [참고] 파이썬이 없습니다 -- 데이터 설계 검사(data-light)·기록 보기 페이지·설명서 검토에만 필요합니다 (3.9 이상, 나머지는 그대로 동작)"
}

if ($Ask.Count -gt 0) {
  Write-Host ""
  Write-Host "[물어볼 것] 아래는 새 판과 다릅니다 (직접 고쳤거나, 예전 설치 기록이 없어 알 수 없음) -- 손대지 않았습니다:"
  foreach ($l in $Ask) { Write-Host $l }
  Write-Host "  사용자에게 물어보고 그 답대로 다시 설치합니다 (권장: 새 판으로 -- 고친 내용이 필요하면 백업에서 다시 옮긴다):"
  Write-Host "    새 판으로:      powershell -ExecutionPolicy Bypass -File install.ps1 `"$Target`" -Update <이름|all>   (지금 것은 .light-backup\ 에 남김)"
  Write-Host "    지금 것을 둠:   powershell -ExecutionPolicy Bypass -File install.ps1 `"$Target`" -Keep <이름|all>"
  Write-Host "  사용자의 답은 dev-notes\DECISIONS.md 에 [사용자] 로 적습니다."
  exit 3
}

Write-Host ""
Write-Host "설치 끝. 이제 이 폴더에서 Claude Code(또는 Codex)를 열고 이렇게 말하세요:"
Write-Host '  "light-resume 으로 시작해 줘"'
