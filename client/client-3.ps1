# Install RSAT and SQL SSMS

Copy-Item "Z:\SSMS-Setup-ENU (1).exe" "C:\SSMS-Setup-ENU.exe"
$SSMSInstallerPath = "C:\SSMS-Setup-ENU.exe"

# Installing RSAT tools
Write-Host "Starting RSAT management tools installation..."
$RSATFeatures = @(
    "RSAT.ActiveDirectory.DS-LDS.Tools",
    "RSAT.DNS.Tools",
    "RSAT.FileServices.Tools",
    "RSAT.GroupPolicy.Management.Tools",
    "RSAT.ServerManager.Tools",
    "Rsat.DHCP.Tools"
)

foreach ($Feature in $RSATFeatures) {
    Write-Output "Installing feature: $Feature..."
    DISM /Online /Add-Capability /CapabilityName:$Feature~~~~0.0.1.0 | Out-Null
    Write-Host "$Feature has been installed succesfully."
}

Write-Output "All RSAT tools have been installed."

# Installing SSMS
Write-Host "Installing SQL Server Management Studio (SSMS)..."
if (Test-Path $SSMSInstallerPath) {
    Start-Process -FilePath $SSMSInstallerPath -ArgumentList "/install /quiet /norestart" -Wait
    Write-Host "SQL Server Management Studio installed succesfully."
}
else {
    Write-Warning "Could not locate SSMS installer at path: $SSMSInstallerPath."
}

# Verifying installation
Write-Output "Verifying all installations..."
foreach ($Feature in $RSATFeatures) {
    $State = Get-WindowsOptionalFeature -Online -FeatureName $Feature | Select-Object -ExpandProperty State
    Write-Host "Feature: $Feature, Status: $State"
}

Write-Host "Script execution completed succesfully."