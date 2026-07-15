param()

$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Vivado = $env:VIVADO_BIN
if (-not $Vivado) {
    $Vivado = 'D:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
}
if (-not (Test-Path -LiteralPath $Vivado)) {
    $VivadoCommand = Get-Command vivado.bat -ErrorAction SilentlyContinue
    if (-not $VivadoCommand) {
        throw 'Vivado was not found. Set VIVADO_BIN to vivado.bat.'
    }
    $Vivado = $VivadoCommand.Source
}

$VivadoBin = Split-Path $Vivado -Parent
$WorkDir = Join-Path $Repo '.numeric_test_work'
$VectorDir = Join-Path $WorkDir 'verification'

if (Test-Path -LiteralPath $WorkDir) {
    Remove-Item -LiteralPath $WorkDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $VectorDir | Out-Null
Copy-Item -Force (Join-Path $Repo 'verification\posit8_add_expected.mem') $VectorDir
Copy-Item -Force (Join-Path $Repo 'verification\posit8_mul_expected.mem') $VectorDir

$Sources = @(
    'verilog\decoder\posit_decoder.v',
    'verilog\posit\posit_round_pack.v',
    'verilog\posit\posit_to_quire.v',
    'verilog\posit\quire_to_posit.v',
    'verilog\adder\posit_adder.v',
    'verilog\multiplier\posit_multiplier.v',
    'verilog\pe\pe_quire.v',
    'verilog\posit\tb_posit_arithmetic_exhaustive.v',
    'verilog\posit\tb_posit_quire_conversion.v',
    'verilog\posit\tb_pe_quire_product_exhaustive.v'
) | ForEach-Object { Join-Path $Repo $_ }

Push-Location $WorkDir
$AllPassed = $false
try {
    & (Join-Path $VivadoBin 'xvlog.bat') @Sources
    if ($LASTEXITCODE -ne 0) { throw 'xvlog failed.' }

    $Tests = @(
        [pscustomobject]@{ Top = 'tb_posit_arithmetic_exhaustive'; Snapshot = 'posit_arithmetic_test' },
        [pscustomobject]@{ Top = 'tb_posit_quire_conversion'; Snapshot = 'quire_conversion_test' },
        [pscustomobject]@{ Top = 'tb_pe_quire_product_exhaustive'; Snapshot = 'pe_quire_product_test' }
    )
    foreach ($Test in $Tests) {
        & (Join-Path $VivadoBin 'xelab.bat') $Test.Top -s $Test.Snapshot
        if ($LASTEXITCODE -ne 0) { throw "xelab failed for $($Test.Top)." }
        & (Join-Path $VivadoBin 'xsim.bat') $Test.Snapshot -runall
        if ($LASTEXITCODE -ne 0) { throw "xsim failed for $($Test.Top)." }
    }
    $AllPassed = $true
}
finally {
    Pop-Location
    if ($AllPassed) {
        Remove-Item -LiteralPath $WorkDir -Recurse -Force
    }
}

Write-Host 'All exhaustive Posit and quire unit tests passed.'
