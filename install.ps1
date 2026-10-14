# dev-process-light 설치 -- Windows PowerShell (5.1 이상)
#   powershell -ExecutionPolicy Bypass -File install.ps1 [프로젝트 폴더]   (생략하면 현재 폴더)
# install.sh 와 같은 일을 한다: 스킬 복사(light-* 7개 + 짝 데이터 설계 스킬 data-light), dev-notes 는 없을 때만,
# AGENTS.md 블록 넣기/갱신, CLAUDE.md 연결.
param([string]$Target = ".")
$ErrorActionPreference = "Stop"

$Kit = Join-Path $PSScriptRoot "kit"
$Begin = "<!-- dev-process-light:begin -->"
$End = "<!-- dev-process-light:end -->"
$Utf8 = New-Object System.Text.UTF8Encoding($false)   # BOM 없는 UTF-8

function Read-Utf8($p) { [System.IO.File]::ReadAllText($p, $Utf8) }
function Write-Utf8($p, $s) { [System.IO.File]::WriteAllText($p, $s, $Utf8) }

if (-not (Test-Path (Join-Path $Kit "skills"))) { Write-Error "kit 폴더를 찾을 수 없습니다: $Kit" }
New-Item -ItemType Directory -Force -Path $Target | Out-Null
$Target = (Resolve-Path $Target).Path
Write-Host "dev-process-light 설치 -> $Target"

# 1) 스킬
foreach ($hostDir in @(".claude\skills", ".agents\skills")) {
  $dest = Join-Path $Target $hostDir
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  Get-ChildItem -Directory (Join-Path $Kit "skills") | ForEach-Object {
    $d = Join-Path $dest $_.Name
    if (Test-Path $d) { Remove-Item -Recurse -Force $d }
    Copy-Item -Recurse $_.FullName $d
  }
  Write-Host "  [OK] 스킬 $((Get-ChildItem -Directory (Join-Path $Kit "skills")).Count)개 -> $hostDir"
}
$Lock = Join-Path $PSScriptRoot "data-light.lock.json"
if (Test-Path $Lock) {
  $pin = (Read-Utf8 $Lock) | ConvertFrom-Json
  Write-Host "  [OK] 짝 스킬 data-light $($pin.version) (data-expert-framework-light $($pin.commit.Substring(0, 7))) -- 저장할 데이터가 생기면 씁니다"
}
# 데이터 검사 장치(datalight.py hook install)가 프로젝트에 둔 도구 사본도 짝 버전으로 맞춘다
$Dlt = Join-Path $Kit "skills\data-light\scripts\datalight.py"
$DltDest = Join-Path $Target ".data-light\datalight.py"
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
if (-not (Test-Path $a)) {
  Write-Utf8 $a $block; Write-Host "  [OK] AGENTS.md 만듦"
} else {
  $cur = Read-Utf8 $a
  $i = $cur.IndexOf($Begin); $j = $cur.IndexOf($End)
  if ($i -ge 0 -and $j -gt $i) {
    $after = $cur.Substring($j + $End.Length).TrimStart("`r", "`n")
    $new = $cur.Substring(0, $i) + $block.TrimEnd("`r", "`n") + "`n" + $after
    Write-Utf8 $a $new; Write-Host "  [OK] AGENTS.md 규칙 블록 갱신 (다른 내용은 그대로)"
  } else {
    Write-Utf8 $a ($cur.TrimEnd("`r", "`n") + "`n`n" + $block); Write-Host "  [OK] AGENTS.md 끝에 규칙 블록 추가"
  }
}

# 4) CLAUDE.md
$c = Join-Path $Target "CLAUDE.md"
if (-not (Test-Path $c)) { Write-Utf8 $c "@AGENTS.md`n"; Write-Host "  [OK] CLAUDE.md 만듦 (@AGENTS.md)" }
elseif (-not ((Read-Utf8 $c).Contains("@AGENTS.md"))) {
  Write-Utf8 $c ((Read-Utf8 $c).TrimEnd("`r", "`n") + "`n`n@AGENTS.md`n"); Write-Host "  [OK] CLAUDE.md 에 @AGENTS.md 추가"
} else { Write-Host "  [유지] CLAUDE.md" }

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

Write-Host ""
Write-Host "설치 끝. 이제 이 폴더에서 Claude Code(또는 Codex)를 열고 이렇게 말하세요:"
Write-Host '  "light-resume 으로 시작해 줘"'
