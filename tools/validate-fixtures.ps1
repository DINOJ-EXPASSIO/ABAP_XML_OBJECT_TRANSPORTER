$ErrorActionPreference = 'Stop'

$fixtureRoot = Join-Path $PSScriptRoot '..\test\fixtures'
if (-not (Test-Path -LiteralPath $fixtureRoot)) {
  Write-Host 'No fixtures yet; structural validation skipped.'
  exit 0
}

$fixtures = Get-ChildItem -LiteralPath $fixtureRoot -Filter '*.xml' -File
foreach ($fixture in $fixtures) {
  try {
    [xml](Get-Content -LiteralPath $fixture.FullName -Raw) | Out-Null
  } catch {
    throw "Invalid XML fixture: $($fixture.FullName)"
  }
}

Write-Host "Validated $($fixtures.Count) XML fixture(s)."
