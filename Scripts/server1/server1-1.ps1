# IP instellen en Shared folder copyen

# Variables
$IFNAME = "Ethernet 2"
$GW = "192.168.25.1"
$IP = "192.168.25.10"
$SF = "C:\vagrant"
$LOCALPATH = "C:\Users\Public\shared_folder"

# Open port 22 for SSH
New-NetFirewallRule -DisplayName "Allow SSH" -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow

# Static IP
Write-Host "Configuring static IPv4"
New-NetIPAddress -InterfaceAlias $IFNAME -IPAddress $IP -PrefixLength 24 -DefaultGateway $GW
Set-DnsClientServerAddress -InterfaceAlias $IFNAME -ServerAddresses $IP
Write-Output "Static IP set to $IP on interface $IFNAME"

# Copy shared folder locally
Write-Output "Copying shared folder to the local path."
if (!(Test-Path $LOCALPATH)) {
    New-Item -Path $LOCALPATH -ItemType Directory -Force
    Write-Output "Local path created at $LOCALPATH."
}
Copy-Item -Path $SF\* -Destination $LOCALPATH -Recurse -Force
Write-Host "Shared folder successfully copied to $LOCALPATH."

# Install required packages
Write-Host "Installing required Windows features."
Install-WindowsFeature -Name DHCP, AD-Domain-Services, DNS -IncludeManagementTools
Write-Output "All required packages installed successfully."

# Configure firewall
Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled True
New-NetFirewallRule -DisplayName "Allow SSH" -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow
