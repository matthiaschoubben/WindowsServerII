# IP instellen en Shared folder copyen

# Variables
$IFNAME = "Ethernet 2"
$DOMAIN = "ws2-25-matthias.hogent"
$USER = "Administrator"
$PASS = "vagrant"
$SECUREPASS = ConvertTo-SecureString $PASS -AsPlainText -Force
$CREDENTIAL = New-Object System.Management.Automation.PSCredential("$USER@$DOMAIN", $SECUREPASS)
$SF = "C:\vagrant"
$LOCALPATH = "C:\Users\Public\shared_folder"

# Turn off firewall
netsh advfirewall set all profiles state off

# IP via DHCP
Write-Output "Configuring DHCP settings..."
netsh interface ip set address name=$IFNAME source=dhcp
netsh interface ip set dns name=$IFNAME source=dhcp
Write-Host "DHCP configuration complete."

# Copy shared folder locally
Write-Output "Copying shared folder to the local path."
if (!(Test-Path $LOCALPATH)) {
    New-Item -Path $LOCALPATH -ItemType Directory -Force
    Write-Output "Local path created at $LOCALPATH."
}
Copy-Item -Path $SF\* -Destination $LOCALPATH -Recurse -Force
Write-Host "Shared folder successfully copied to $LOCALPATH."

# Join domain
Write-Host "Joining existing domain: $DOMAIN."
Add-Computer -DomainName $DOMAIN -Credential $CREDENTIAL -Force -Restart
Write-Output "System added to domain $DOMAIN and will restart."