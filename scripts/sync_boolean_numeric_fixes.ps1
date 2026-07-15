param(
    [string]$BuildDir = 'D:/BooleanBuild/posit_cnn_accelerator_boolean'
)

$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Vivado = $env:VIVADO_BIN
if (-not $Vivado) {
    $Vivado = 'D:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
}

if (-not (Test-Path -LiteralPath $Vivado)) {
    $VivadoCommand = Get-Command vivado.bat -ErrorAction SilentlyContinue
    if (-not $VivadoCommand) {
        throw "Vivado was not found. Set VIVADO_BIN to vivado.bat."
    }
    $Vivado = $VivadoCommand.Source
}

$env:POSIT_CNN_PROJECT_DIR = $Repo
$env:BOOLEAN_BUILD_DIR = $BuildDir
$VivadoRoot = Split-Path (Split-Path $Vivado -Parent) -Parent
$env:XILINX_TCLAPP_REPO = (Join-Path $VivadoRoot 'data\XilinxTclStore').Replace('\', '/')
$env:TCLLIBPATH = (Join-Path $VivadoRoot 'data\XilinxTclStore\support\appinit').Replace('\', '/')

& $Vivado -mode batch -source (Join-Path $PSScriptRoot 'sync_boolean_numeric_fixes.tcl')
if ($LASTEXITCODE -ne 0) {
    throw 'Boolean project source synchronization failed.'
}

Write-Host "Synchronized corrected RTL into $BuildDir"
