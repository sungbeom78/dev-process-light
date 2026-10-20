# dev-process-light 설치 -- Windows PowerShell (5.1 이상)
#   powershell -ExecutionPolicy Bypass -File install.ps1 [프로젝트 폴더] [-Update <이름>[,<이름>]|all] [-Keep <이름>[,<이름>]|all]   (폴더를 생략하면 현재 폴더)
# install.sh 와 같은 일을 한다: 스킬 복사(light-* 7개 + 짝 데이터 설계 스킬 data-light), dev-notes 는 없을 때만,
# AGENTS.md 블록 넣기/갱신, CLAUDE.md 연결.
# 새 판 반영이 원칙, 다만 직접 고치거나 지운 스킬 · 규칙 블록은 말없이 덮거나 되살리지 않는다 (소유자 원칙 2026-10-20 -- 어느 쪽을 둘지는 사용자가 정한다):
#   지난번에 설치한 그대로(또는 손대지 않은 예전 판)면 새 판으로, 고치거나 지운 것이면 손대지 않고 '물어볼 것'으로 알린 뒤 3 으로 끝난다.
#   -Update <이름|all> 새 판으로 (지금 것은 .claude\skills\.light-backup\ 에) · -Keep <이름|all> 지금 것을 둔다. <이름> = 스킬 이름 또는 AGENTS, 여럿은 쉼표로.
#   고른 것은 그 판에 대한 것 -- 새 판이 또 바꾸면 다시 묻는다. 지문 셈법은 install.sh · scripts/kit_hash.py 와 같다. 기록: .claude\skills\.light-kit
param([string]$Target = ".", [string[]]$Update = @(), [string[]]$Keep = @())
$ErrorActionPreference = "Stop"
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch {}   # AI 가 읽는 출력도 한글이 깨지지 않게

$Kit = Join-Path $PSScriptRoot "kit"
$Begin = "<!-- dev-process-light:begin -->"
$End = "<!-- dev-process-light:end -->"
$Utf8 = New-Object System.Text.UTF8Encoding($false)         # BOM 없는 UTF-8
$Utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)   # 잘못된 글자면 멈춘다 (cp949 를 U+FFFD 로 바꿔 쓰지 않게)

function Read-Utf8($p) { [System.IO.File]::ReadAllText($p, $Utf8) }
function Write-Utf8($p, $s) { [System.IO.File]::WriteAllText($p, $s, $Utf8) }
function Read-Strict($p) {
  $b = [System.IO.File]::ReadAllBytes($p)
  $s = $Utf8Strict.GetString($b)
  if ($s.Length -gt 0 -and $s[0] -eq [char]0xFEFF) { $s = $s.Substring(1) }
  return $s
}

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
    if ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) { return }        # 심링크는 넣지 않는다 (bash find -type f 와 같게)
    $rel = $_.FullName.Substring($root.Length).TrimStart('\', '/').Replace('\', '/')
    $leaf = $rel.Split('/')[-1]
    if ($leaf -clike '.light-kit*' -or $leaf -clike '*.pyc' -or $leaf -ceq '.DS_Store' -or $leaf -ceq 'Thumbs.db' -or $leaf -ceq 'desktop.ini' -or
        ($rel.Split('/') -ccontains '__pycache__')) { return }
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
  foreach ($line in ((Read-Strict $path).Replace("`r", "") -split "`n")) {
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

if (-not (Test-Path (Join-Path $Kit "skills"))) { Write-Error "kit 폴더를 찾을 수 없습니다: $Kit" }
$KitSkills = Get-ChildItem -Directory (Join-Path $Kit "skills")
$Names = @("AGENTS", "all") + @($KitSkills | ForEach-Object { $_.Name })
function Get-Picks($list) {   # 쉼표로 여럿 · '.claude/skills/<이름>' 모양도 받는다
  $out = @()
  foreach ($v in @($list | ForEach-Object { $_ -split ',' } | Where-Object { $_ })) {
    $n = ($v -split '[\\/]')[-1]
    if ($Names -cnotcontains $n) { Write-Host "[실패] 모르는 이름: $v (스킬 이름 · AGENTS · all 중에서)"; exit 2 }
    $out += $n
  }
  return ,$out
}
$Update = Get-Picks $Update
$Keep = Get-Picks $Keep
function Test-Wants($name, $list) { return ($list -ccontains "all") -or ($list -ccontains $name) }

New-Item -ItemType Directory -Force -Path $Target | Out-Null
$Target = (Resolve-Path $Target).Path
Write-Host "dev-process-light 설치 -> $Target"

$StateFile = Join-Path $Target ".claude/skills/.light-kit"     # 경로는 / 로 (Windows 도 받는다 -- 다른 OS 의 pwsh 로도 시험)
$OldState = @()
if (Test-Path -LiteralPath $StateFile) { $OldState = (Read-Utf8 $StateFile).Replace("`r", "") -split "`n" }
$Hist = @()
if (Test-Path (Join-Path $Kit ".history")) { $Hist = (Read-Utf8 (Join-Path $Kit ".history")).Replace("`r", "") -split "`n" }
$NewState = New-Object System.Collections.Generic.List[string]
function Get-State($kind, $key, $i = 2) {
  foreach ($l in $OldState) { $p = $l -split ' '; if ($p.Count -gt $i -and $p[0] -ceq $kind -and $p[1] -ceq $key) { return $p[$i] } }
  return ""
}
function Add-State($kind, $key, $hash, $want = $null) { if ($hash) { $NewState.Add((@($kind, $key, $hash) + @($want | Where-Object { $_ })) -join ' ') } }
function Test-Kept($key, $have, $want) { return ((Get-State keep $key 2) -ceq $have) -and ((Get-State keep $key 3) -ceq $want) }
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$Bk = ".claude/skills/.light-backup/$Stamp"       # 설치된 스킬 자리 안 -- 데이터 검사 · CI 가 보지 않는 곳
$Ask = New-Object System.Collections.Generic.List[string]
function Add-Ask($label, $key, $have, $want) { $Ask.Add("  - $label"); Add-State ask $key $have $want }
function Save-Backup($src, $rel) {
  $d = Join-Path $Target "$Bk/$rel"
  New-Item -ItemType Directory -Force -Path (Split-Path $d) | Out-Null
  Copy-Item -Recurse -LiteralPath $src $d
  if (-not (Test-Path -LiteralPath $d)) { throw "백업하지 못함: $rel" }
  return "$Bk/$rel"
}

# 1) 스킬
foreach ($hostDir in @(".claude/skills", ".agents/skills")) {
  $dest = Join-Path $Target $hostDir
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  foreach ($s in $KitSkills) {
    $d = Join-Path $dest $s.Name
    $key = "$hostDir/$($s.Name)"
    $want = Get-TreeHash $s.FullName
    $prev = Get-State installed $key
    if (-not (Test-Path -LiteralPath $d)) {
      if (-not $prev -or (Test-Wants $s.Name $Update)) { Copy-Item -Recurse $s.FullName $d; Add-State installed $key $want; continue }
      Add-State installed $key $prev                                   # 전에 설치했는데 지웠다 -- 말없이 되살리지 않는다
      if ((Test-Wants $s.Name $Keep) -or (Test-Kept $key "-" $want)) { Add-State keep $key "-" $want; Write-Host "  [유지] $key 없음 (지운 채로 두기로 함 -- 사용자 결정)" }
      else { Add-Ask "$key (스킬 $($s.Name) -- 지웠음)" $key "-" $want }
      continue
    }
    $have = Get-TreeHash $d
    if ($have -eq $want) { Add-State installed $key $want; continue }
    if ($prev -eq $have -or ($Hist -contains "skill $($s.Name) $have")) {
      Remove-Item -Recurse -Force -LiteralPath $d; Copy-Item -Recurse $s.FullName $d; Add-State installed $key $want; continue
    }
    if (Test-Wants $s.Name $Update) {
      $b = Save-Backup $d $key
      Remove-Item -Recurse -Force -LiteralPath $d; Copy-Item -Recurse $s.FullName $d; Add-State installed $key $want
      Write-Host "  [OK] ${key}: 새 판으로 바꿈 (사용자 결정 -- 예전 것은 $b)"; continue
    }
    Add-State installed $key $prev
    if ((Test-Wants $s.Name $Keep) -or (Test-Kept $key $have $want)) {
      Add-State keep $key $have $want; Write-Host "  [유지] $key (직접 고친 것을 두기로 함 -- 사용자 결정)"; continue
    }
    Add-Ask "$key (스킬 $($s.Name))" $key $have $want
  }
  Write-Host "  [OK] 스킬 $($KitSkills.Count)개 -> $hostDir"
}
$Lock = Join-Path $PSScriptRoot "data-light.lock.json"
if (Test-Path $Lock) {
  $pin = (Read-Utf8 $Lock) | ConvertFrom-Json
  Write-Host "  [OK] 짝 스킬 data-light $($pin.version) (data-expert-framework-light $($pin.commit.Substring(0, 7))) -- 저장할 데이터가 생기면 씁니다"
}
# 데이터 검사 장치(datalight.py hook install)가 프로젝트에 둔 도구 사본도 짝 버전으로 맞춘다 (도구 사본은 고치는 곳이 아니다)
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
$prevB = Get-State installed AGENTS
function Set-Block {   # 첫 블록(시작 줄 머리 ~ 끝 줄 머리)만 새 판으로 -- 다른 줄은 그대로 (줄 단위로 찾는다)
  $lines = (Read-Strict $a) -split "`n"
  $i = -1; $j = -1
  for ($k = 0; $k -lt $lines.Count; $k++) {
    $l = $lines[$k].TrimEnd("`r")
    if ($i -lt 0 -and $l.StartsWith($Begin)) { $i = $k; continue }
    if ($i -ge 0 -and $l.StartsWith($End)) { $j = $k; break }
  }
  if ($i -lt 0 -or $j -lt 0) { throw "규칙 블록을 찾지 못함" }
  $before = if ($i -gt 0) { ($lines[0..($i - 1)] -join "`n") + "`n" } else { "" }
  $after = if ($j -lt $lines.Count - 1) { "`n" + ($lines[($j + 1)..($lines.Count - 1)] -join "`n") } else { "" }
  Write-Utf8 $a ($before + $block.TrimEnd("`r", "`n") + $after)
}
$agentsOk = $true
if (Test-Path $a) {
  try { [void](Read-Strict $a) } catch { $agentsOk = $false }
}
if (-not $agentsOk) {
  Write-Host "  [유지] AGENTS.md 를 UTF-8 로 읽지 못해 손대지 않았습니다 -- UTF-8 로 저장한 뒤 다시 설치합니다"
  $Ask.Add("  - AGENTS (AGENTS.md 가 UTF-8 이 아님 -- 메모장 등에서 UTF-8 로 저장)")
  Add-State installed AGENTS $prevB
} elseif (-not (Test-Path $a) -and -not $prevB) {
  Write-Utf8 $a $block; Add-State installed AGENTS $wantB; Write-Host "  [OK] AGENTS.md 만듦"
} else {
  $haveB = Get-BlockHash $a
  if (-not $haveB) {
    if (-not $prevB -or (Test-Wants "AGENTS" $Update)) {
      if (Test-Path $a) { Write-Utf8 $a ((Read-Strict $a).TrimEnd("`r", "`n") + "`n`n" + $block) } else { Write-Utf8 $a $block }
      Add-State installed AGENTS $wantB; Write-Host "  [OK] AGENTS.md 에 규칙 블록 넣음"
    } else {
      Add-State installed AGENTS $prevB                                 # 전에 넣었는데 지웠다 -- 말없이 되살리지 않는다
      if ((Test-Wants "AGENTS" $Keep) -or (Test-Kept AGENTS "-" $wantB)) { Add-State keep AGENTS "-" $wantB; Write-Host "  [유지] AGENTS.md 규칙 블록 없음 (지운 채로 두기로 함 -- 사용자 결정)" }
      else { Add-Ask "AGENTS (AGENTS.md 의 규칙 블록 -- 지웠음)" AGENTS "-" $wantB }
    }
  } elseif ($haveB -eq $wantB) {
    Add-State installed AGENTS $wantB; Write-Host "  [유지] AGENTS.md 규칙 블록 (새 판과 같음)"
  } elseif ($prevB -eq $haveB -or ($Hist -contains "block $haveB")) {
    Set-Block; Add-State installed AGENTS $wantB; Write-Host "  [OK] AGENTS.md 규칙 블록 갱신 (다른 내용은 그대로)"
  } elseif (Test-Wants "AGENTS" $Update) {
    $bd = Join-Path $Target $Bk; New-Item -ItemType Directory -Force -Path $bd | Out-Null
    Write-Utf8 (Join-Path $bd "AGENTS.block.md") (Get-BlockText $a)
    Set-Block; Add-State installed AGENTS $wantB
    Write-Host "  [OK] AGENTS.md 규칙 블록: 새 판으로 바꿈 (사용자 결정 -- 예전 블록은 $Bk/AGENTS.block.md)"
  } else {
    Add-State installed AGENTS $prevB
    if ((Test-Wants "AGENTS" $Keep) -or (Test-Kept AGENTS $haveB $wantB)) {
      Add-State keep AGENTS $haveB $wantB; Write-Host "  [유지] AGENTS.md 규칙 블록 (직접 고친 것을 두기로 함 -- 사용자 결정)"
    } else { Add-Ask "AGENTS (AGENTS.md 의 규칙 블록)" AGENTS $haveB $wantB }
  }
}

# 4) CLAUDE.md
$c = Join-Path $Target "CLAUDE.md"
if (-not (Test-Path $c)) { Write-Utf8 $c "@AGENTS.md`n"; Write-Host "  [OK] CLAUDE.md 만듦 (@AGENTS.md)" }
elseif (-not ((Read-Utf8 $c).Contains("@AGENTS.md"))) {
  Write-Utf8 $c ((Read-Utf8 $c).TrimEnd("`r", "`n") + "`n`n@AGENTS.md`n"); Write-Host "  [OK] CLAUDE.md 에 @AGENTS.md 추가"
} else { Write-Host "  [유지] CLAUDE.md" }

# 설치 기록 (다음 설치가 '직접 고쳤나'를 알아본다 · ask 줄은 아직 묻지 않은 것 -- light-resume 이 본다)
Write-Utf8 "$StateFile.tmp" ("# dev-process-light 설치 기록 -- 다음 설치가 직접 고친 것을 알아보려고 (지우면 다음 설치가 한 번 더 묻는다)`n" + (-join ($NewState | ForEach-Object { $_ + "`n" })))
Move-Item -Force "$StateFile.tmp" $StateFile

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
  Write-Host "[물어볼 것] 아래는 새 판과 다릅니다 (직접 고쳤거나 지웠음, 또는 예전 설치 기록이 없어 알 수 없음) -- 손대지 않았습니다:"
  foreach ($l in $Ask) { Write-Host $l }
  Write-Host "  사용자에게 물어보고 그 답대로 다시 설치합니다 (권장: 새 판으로 -- 고친 내용이 필요하면 백업에서 다시 옮긴다):"
  Write-Host "    새 판으로:      powershell -ExecutionPolicy Bypass -File `"$PSCommandPath`" `"$Target`" -Update <이름|all>   (지금 것은 .claude\skills\.light-backup\ 에 남김)"
  Write-Host "    지금 것을 둠:   powershell -ExecutionPolicy Bypass -File `"$PSCommandPath`" `"$Target`" -Keep <이름|all>"
  Write-Host "  <이름> 은 스킬 이름(light-check 등)이나 AGENTS, 여럿은 쉼표로. 사용자의 답은 dev-notes\DECISIONS.md 에 [사용자] 로 적습니다."
  exit 3
}

Write-Host ""
Write-Host "설치 끝. 이제 이 폴더에서 Claude Code(또는 Codex)를 열고 이렇게 말하세요:"
Write-Host '  "light-resume 으로 시작해 줘"'
