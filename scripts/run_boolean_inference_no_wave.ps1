param(
    [string]$BuildDir = 'D:\BooleanBuild\posit_cnn_accelerator_boolean'
)

$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$VivadoExe = $env:VIVADO_BIN
if (-not $VivadoExe) {
    $VivadoExe = 'D:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
}
if (-not (Test-Path -LiteralPath $VivadoExe)) {
    $VivadoCommand = Get-Command vivado.bat -ErrorAction SilentlyContinue
    if (-not $VivadoCommand) {
        throw "Vivado was not found. Set VIVADO_BIN to vivado.bat."
    }
    $VivadoExe = $VivadoCommand.Source
}
$VivadoBin = Split-Path $VivadoExe -Parent
$Snapshot = 'tb_boolean_accelerator_10_image_inference_behav'
$SimDir = Join-Path $BuildDir 'posit_cnn_accelerator_boolean.sim\sim_1\behav\xsim'

$env:BOOLEAN_BUILD_DIR = $BuildDir.Replace('\', '/')
$env:XILINX_LOCAL_USER_DATA = 'no'
$VivadoRoot = Split-Path $VivadoBin -Parent
$env:XILINX_TCLAPP_REPO = (Join-Path $VivadoRoot 'data\XilinxTclStore').Replace('\', '/')
$env:TEMP = Join-Path $BuildDir 'VivadoTemp'
$env:TMP = $env:TEMP
New-Item -ItemType Directory -Force -Path $env:TEMP | Out-Null

& $VivadoExe -mode batch `
    -source (Join-Path $PSScriptRoot 'compile_boolean_inference_sim.tcl')
if ($LASTEXITCODE -ne 0) {
    throw 'Boolean inference compilation/elaboration failed.'
}

Push-Location $SimDir
try {
    & (Join-Path $VivadoBin 'xsim.bat') $Snapshot `
        -tclbatch (Join-Path $Repo 'scripts\run_boolean_inference_nowave.tcl') `
        -log 'boolean_inference_no_wave.log'
    if ($LASTEXITCODE -ne 0) {
        throw 'Boolean ten-image inference simulation failed.'
    }
}
finally {
    Pop-Location
}

Write-Host "Results: $SimDir\boolean_inference_no_wave.log"
