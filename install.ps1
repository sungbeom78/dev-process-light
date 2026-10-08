# dev-process-light 설치 -- Windows PowerShell (5.1 이상)
#   powershell -ExecutionPolicy Bypass -File install.ps1 [프로젝트 폴더]   (생략하면 현재 폴더)
# install.sh 와 같은 일을 한다: 스킬 복사, dev-notes 는 없을 때만, AGENTS.md 블록 넣기/갱신, CLAUDE.md 연결.
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
  Write-Host "  [OK] 스킬 5개 -> $hostDir"
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

Write-Host ""
Write-Host "설치 끝. 이제 이 폴더에서 Claude Code(또는 Codex)를 열고 이렇게 말하세요:"
Write-Host '  "light-resume 으로 시작해 줘"'
