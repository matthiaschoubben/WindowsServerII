# DNS and SQL server config

# Variables
$DNS = "192.168.25.11"
$REVERSE_ZONE = "25.168.192.in-addr.arpa"
$DOMAIN = "ws2-25-matthias.hogent"
Copy-Item "Z:\enu_sql_server_2022_standard_edition_x64_dvd_43079f69.iso" "C:\SQL2022.iso"
$ISO = "C:\SQL2022.iso"
$PathToAdd = "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\"
$CurrentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

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


# Configure SQL Server

# Move iso to local path
Copy-Item "Z:\enu_sql_server_2022_standard_edition_x64_dvd_43079f69.iso" "C:\SQL2022.iso"
$ISO = "C:\SQL2022.iso"

# Mount ISO
Write-Host "Mounting the SQL ISO."
Mount-DiskImage -ImagePath $ISO
Start-Sleep -Seconds 5
$MountedDrives = Get-Volume | Where-Object { $_.DriveType -eq 'CD-ROM' } | Select-Object -ExpandProperty DriveLetter

if (-not $MountedDrives -or $MountedDrives.Count -eq 0) {
    Write-Output "Failed to locate setup.exe in the mounted ISO."
    exit 1
}

$MountedDrive = $MountedDrives[0]
Write-Output "Mounted ISO detected at drive: $MountedDrive`:"

# Temp dir for setup
Write-Host "Copying ISO file to temp directory."
New-Item -Path "C:\" -Name "tempsql" -ItemType "Directory" -Force
Copy-Item -Path $MountedDrive":\*" -Destination "C:\tempsql" -Recurse

# Variables for SQL setup
$setupPath = "C:\tempsql\setup.exe"
$configPath = "C:\Users\administrator\shared_folder\ConfigurationFile.ini"

Write-Output "Running SQL setup."
Set-ItemProperty -Path "$setupPath" -Name "IsReadOnly" -Value $false
Start-Process -FilePath "$setupPath" -ArgumentList "/ConfigurationFile=$configPath /Q" -Wait

if ($CurrentPath -notlike "*$PathToAdd*") {
    $NewPath = "$CurrentPath;$PathToAdd"
    [Environment]::SetEnvironmentVariable("Path", $NewPath, "Machine")
    Write-Host "Path updated sucessfully. Restart required to take effect."
}
else {
    Write-Output "Path is already set."
}

$env:Path += ";$PathToAdd"
New-NetFirewallRule -DisplayName "Allow SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow

Write-Output "Restarting Device to apply changes."
Restart-Computer -Force