param(
    [ValidateSet(0, 1)]
    [int]$UseQuire = 1,
    [switch]$BuildBitstream,
    [string]$BuildDir = 'D:\BooleanBuild\posit_cnn_accelerator_boolean'
)

$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Vivado = $env:VIVADO_BIN
if (-not $Vivado) {
    $Vivado = 'D:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
}
$Python = $env:PYTHON_BIN
if (-not $Python) {
    $Python = (Get-Command python -ErrorAction SilentlyContinue).Source
}
$ModelDir = Join-Path $Repo 'VGG16_MNIST_Epoch20'
if (-not (Test-Path -LiteralPath $ModelDir)) {
    $ModelDir = Join-Path $Repo 'verilog\params'
}

if (-not (Test-Path -LiteralPath $Vivado)) {
    $VivadoCommand = Get-Command vivado.bat -ErrorAction SilentlyContinue
    if (-not $VivadoCommand) {
        throw "Vivado was not found. Set VIVADO_BIN to vivado.bat."
    }
    $Vivado = $VivadoCommand.Source
}
if (-not $Python) {
    throw "Python was not found. Set PYTHON_BIN to a Python executable."
}

$env:POSIT_CNN_PROJECT_DIR = $Repo
$env:BOOLEAN_BUILD_DIR = $BuildDir
$env:BOOLEAN_USE_QUIRE = [string]$UseQuire
$VivadoRoot = Split-Path (Split-Path $Vivado -Parent) -Parent
$env:XILINX_TCLAPP_REPO = (Join-Path $VivadoRoot 'data\XilinxTclStore').Replace('\', '/')
$env:TCLLIBPATH = (Join-Path $VivadoRoot 'data\XilinxTclStore\support\appinit').Replace('\', '/')

& $Vivado -mode batch -source (Join-Path $PSScriptRoot 'create_boolean_deployment_project.tcl')
if ($LASTEXITCODE -ne 0) {
    throw 'Boolean-board project generation failed.'
}

if ($BuildBitstream) {
    & $Python (Join-Path $PSScriptRoot 'pack_boolean_flash.py') `
        --model-dir $ModelDir `
        --output (Join-Path $BuildDir 'flash\boolean_model_images.bin') `
        --layout (Join-Path $BuildDir 'flash\boolean_flash_layout.json')
    if ($LASTEXITCODE -ne 0) {
        throw 'Boolean-board flash payload generation failed.'
    }
    & $Vivado -mode batch -source (Join-Path $PSScriptRoot 'build_boolean_bitstream.tcl')
    if ($LASTEXITCODE -ne 0) {
        throw 'Boolean-board bitstream build failed.'
    }
}

Write-Host "Boolean project: $BuildDir\posit_cnn_accelerator_boolean.xpr"
