param(
    [string]$BuildDir = 'D:\BooleanBuild\posit_cnn_accelerator_boolean'
)

$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Python = $env:PYTHON_BIN
if (-not $Python) {
    $Python = (Get-Command python -ErrorAction SilentlyContinue).Source
}
$Vivado = $env:VIVADO_BIN
if (-not $Vivado) {
    $Vivado = 'D:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
}
$ModelDir = Join-Path $Repo 'VGG16_MNIST_Epoch20'
if (-not (Test-Path -LiteralPath $ModelDir)) {
    $ModelDir = Join-Path $Repo 'verilog\params'
}
if (-not $Python) {
    throw "Python was not found. Set PYTHON_BIN to a Python executable."
}
if (-not (Test-Path -LiteralPath $Vivado)) {
    $VivadoCommand = Get-Command vivado.bat -ErrorAction SilentlyContinue
    if (-not $VivadoCommand) {
        throw "Vivado was not found. Set VIVADO_BIN to vivado.bat."
    }
    $Vivado = $VivadoCommand.Source
}

$env:POSIT_CNN_PROJECT_DIR = $Repo
$env:BOOLEAN_BUILD_DIR = $BuildDir.Replace('\', '/')
$env:XILINX_LOCAL_USER_DATA = 'no'
$VivadoRoot = Split-Path (Split-Path $Vivado -Parent) -Parent
$env:XILINX_TCLAPP_REPO = (Join-Path $VivadoRoot 'data\XilinxTclStore').Replace('\', '/')

$LabelBin = Join-Path $Repo 'mnist_test.bin'
if (Test-Path -LiteralPath $LabelBin) {
    & $Python (Join-Path $PSScriptRoot 'derive_mnist_expected_labels.py') `
        --bin $LabelBin --images 10
    if ($LASTEXITCODE -ne 0) {
        throw 'Expected-label generation failed.'
    }
} else {
    Write-Host 'Using the checked-in ten-image expected-label include.'
}

& $Python (Join-Path $PSScriptRoot 'pack_boolean_flash.py') `
    --model-dir $ModelDir `
    --output (Join-Path $BuildDir 'flash\boolean_model_images.bin') `
    --layout (Join-Path $BuildDir 'flash\boolean_flash_layout.json') `
    --mem-output (Join-Path $BuildDir 'flash\boolean_model_images.mem')
if ($LASTEXITCODE -ne 0) {
    throw 'Simulation flash-payload generation failed.'
}

& $Vivado -mode batch -source (Join-Path $PSScriptRoot 'add_boolean_inference_sim.tcl')
if ($LASTEXITCODE -ne 0) {
    throw 'Adding the Boolean inference simulation to Vivado failed.'
}

Write-Host "Simulation top: tb_boolean_accelerator_10_image_inference"
Write-Host "Project: $BuildDir\posit_cnn_accelerator_boolean.xpr"
