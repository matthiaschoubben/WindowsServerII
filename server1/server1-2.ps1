# Promote to domain controller

# Variables
$NAME = "ws2-25-matthias.hogent"
$PASS = "Password123"

# Promote to dc
Write-Output "Promoting server1 to domain controller"
Install-ADDSForest -DomainName $NAME `
    -ForestMode Win2025 `
    -DomainMode Win2025 `
    -InstallDns `
    -SafeModeAdministratorPassword (ConvertTo-SecureString $PASS -AsPlainText -Force) `
    -Force
Write-Host "SERVER1 successfully promoted to domain controller."