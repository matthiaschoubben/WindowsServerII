# DNS and SQL server config

# Variables
$DNS = "192.168.25.10"
$REVERSE_ZONE = "25.168.192.in-addr.arpa"
$DOMAIN = "ws2-25-matthias.hogent"

# Configure DNS
Write-Output "Configuring secondary DNS server."
# Configure the forward lookup zone
if (-not (Get-DnsServerZone -Name $DOMAIN -ErrorAction SilentlyContinue)) {
    Add-DnsServerSecondaryZone -Name $DOMAIN -MasterServers $DNS -ZoneFile "$DOMAIN.DNS"
    Write-Host "Forward lookup zone for $DOMAIN added successfully."
}
else {
    Write-Output "Forward lookup zone for $DOMAIN already exists. Skipping."
}

# Configure the reverse lookup zone
if (-not (Get-DnsServerZone -Name $REVERSE_ZONE -ErrorAction SilentlyContinue)) {
    Add-DnsServerSecondaryZone -Name $REVERSE_ZONE -MasterServers $DNS -ZoneFile "$REVERSE_ZONE.DNS"
    Write-Host "Reverse lookup zone for $REVERSE_ZONE added successfully."
}
else {
    Write-Output "Reverse lookup zone for $REVERSE_ZONE already exists. Skipping."
}

New-NetFirewallRule -DisplayName "Allow ICMPv4-In" -Protocol ICMPv4

# Install SQL

# Variables
$sqlSetupPath = "Z:\sql\enu_sql_server_2022_standard_edition_x64_dvd_43079f69\setup.exe"
$sqlConfigFile = "Z:\sql\enu_sql_server_2022_standard_edition_x64_dvd_43079f69\sql_config.ini"
$odbcPath = "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\"

# SQL server installation
Write-Host "Starting SQL Server installation..."
if ((Test-Path $sqlSetupPath) -and (Test-Path $sqlConfigFile)) {
    Write-Host "setup.exe and configuration file found, starting installation..."
    Start-Process -FilePath $sqlSetupPath -ArgumentList "/ConfigurationFile=$sqlConfigFile /IACCEPTSQLSERVERLICENSETERMS" -Wait
    Write-Host "SQL Server installation completed."
}
else {
    Write-Error "SQL setup.exe or config file not found. Check paths and try again."
    exit 1
}

# Add path
Write-Host "Updating system PATH variable..."
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($currentPath -notlike "*$odbcPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$odbcPath", "Machine")
    Write-Host "PATH updated. Restart required to take effect."
}
else {
    Write-Host "PATH already contains ODBC tools."
}
Install-Module -Name SqlServer -AllowClobber -Force


$instanceName = "server2"

try {
    $wmi = Get-WmiObject -Namespace "root\Microsoft\SqlServer\ComputerManagement15" -Class "ServerNetworkProtocol" |
    Where-Object { $_.InstanceName -eq $instanceName -and $_.ProtocolName -eq "Tcp" }

    if ($wmi.Enabled -ne $true) {
        $wmi.SetEnable($true)
        Write-Host "TCP/IP protocol enabled for instance $instanceName"
    }
    else {
        Write-Host "TCP/IP protocol already enabled."
    }

    $tcpProps = Get-WmiObject -Namespace "root\Microsoft\SqlServer\ComputerManagement15" -Class "ServerNetworkProtocolProperty" |
    Where-Object { $_.InstanceName -eq $instanceName -and $_.PropertyName -eq "TcpPort" }
    foreach ($prop in $tcpProps) { $prop.SetStringValue("1433") }
    Write-Host "TCP port set to 1433 for instance $instanceName"
}
catch {
    Write-Warning "Could not configure TCP/IP: $_"
}

if (-not (Get-NetFirewallRule -DisplayName "SQL Server TCP 1433" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "SQL Server TCP 1433" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
    netsh advfirewall firewall add rule name="SQL Browser UDP 1434" dir=in action=allow protocol=UDP localport=1434

    Write-Host "Firewall rule added to allow  1433"
}
else {
    Write-Host "Firewall rule already exists."
}



# Write-Output "Restarting device to apply changes.""
# Restart-Computer -Force
