# Config DHCP, DNS, AD, CA

# runas /user:ws2-25-matthias\Administrator

# Varibles
$GW = "192.168.25.1"
$IP = "192.168.25.10"
$IP2 = "192.168.25.20"
$RANGE = "192.168.25.0"
$REVERSE = "25.168.192.in-addr.arpa"
$NAME = "ws2-25-matthias.hogent"

# Authorize DHCP server in AD
Write-Output "Authorizing DHCP Server in the domain controller."
Add-DhcpServerInDC -DnsName $NAME -IPAddress $IP
Write-Output "DHCP server authorized successfully."

# Configure DHCP
Write-Host "Configuring DHCP."
Add-DhcpServerv4Scope -Name "IPScope" -StartRange "192.168.25.50" -EndRange "192.168.25.150" -SubnetMask "255.255.255.0" -State Active
Set-DhcpServerv4OptionValue -ScopeId $RANGE -OptionId 3 -Value $GW
Set-DhcpServerv4OptionValue -ScopeId $RANGE -OptionId 6 -Value $IP, $IP2
Set-DhcpServerv4OptionValue -ScopeId $RANGE -OptionId 15 -Value $NAME
Write-Output "DHCP configuration completed sucessfully."

# Create forward zone (static) 
Add-DnsServerPrimaryZone -Name $NAME -ZoneFile "$NAME.DNS" -DynamicUpdate None
Write-Host "Forward lookup zone $NAME created with static updates."

# Create reverse zone (static)
Add-DnsServerPrimaryZone -NetworkId $RANGE/24 -ZoneFile "$REVERSE.DNS" -DynamicUpdate None
Write-Output "Reverse lookup zone $REVERSE created."

# Disable DNS registration on all non-host-only adapters
$HostOnlyPattern = "Ethernet" # Adjust to match your host-only adapter names
Get-NetAdapter | Where-Object { $_.Name -notlike $HostOnlyPattern } | ForEach-Object {
    Set-DnsClient -InterfaceAlias $_.Name -RegisterThisConnectionsAddress $false
}

# Add static A and PTR records for server1
Add-DnsServerResourceRecordA -Name "server1" -ZoneName $NAME -IPv4Address $IP
Write-Host "DNS A record for server1 added."
Add-DnsServerResourceRecordPtr -Name ($IP.Split('.')[-1]) -ZoneName $REVERSE -PtrDomainName "server1.$NAME"
Write-Host "DNS PTR record for server1 added."

# Add static A and PTR records for server2
Add-DnsServerResourceRecordA -Name "server2" -ZoneName $NAME -IPv4Address $IP2
Write-Host "DNS A record for server2 added."
Add-DnsServerResourceRecordPtr -Name ($IP2.Split('.')[-1]) -ZoneName $REVERSE -PtrDomainName "server2.$NAME"
Write-Host "DNS PTR record for server2 added."

# Configure zone transfers
dnscmd /ZoneResetSecondaries $NAME /SecureList $IP2
dnscmd /ZoneResetSecondaries $REVERSE /SecureList $IP2
Write-Output "Zone transfers configured."

# Configure OU
Write-Output "Configuring OU and user account."
Import-Module ActiveDirectory
New-ADOrganizationalUnit -Name "Domain Admins" -ProtectedFromAccidentalDeletion $false
Write-Host "Organizational Unit 'Domain Admins' created."
New-ADOrganizationalUnit -Name "Domain Users" -ProtectedFromAccidentalDeletion $false
Write-Host "Organizational Unit 'Domain Users' created."

# Configure users
Write-Host "Add users to the OU."
$GEBRUIKERS = Import-Csv "C:\Users\Public\shared_folder\server1\gebruikers.csv" -Delimiter ";"

foreach ($GEBRUIKER in $GEBRUIKERS) {
    $FIRSTNAME = $GEBRUIKER.Voornaam
    $LASTNAME = $GEBRUIKER.Achternaam
    $USERNAME = $GEBRUIKER.Gebruikersnaam
    $PASSWORD = ConvertTo-SecureString $GEBRUIKER.Password -AsPlainText -Force
    $OU = "$($GEBRUIKER.OU),DC=ws2-25-matthias,DC=hogent"

    if (-not (Get-ADUser -F { SamAccountName -eq $USERNAME })) {
        New-ADUser `
            -Name "$FIRSTNAME $LASTNAME" `
            -GivenName "$FIRSTNAME" `
            -Surname "$LASTNAME" `
            -SamAccountName $USERNAME `
            -AccountPassword $PASSWORD `
            -ChangePasswordAtLogon $False `
            -Path $OU `
            -Enabled $true
        Write-Output "User '$USERNAME' created successfully in $OU."
    }
    else {
        Write-Output "User '$USERNAME' already exists."
    }
}

# Configure Certification Authority
Install-WindowsFeature -Name ADCS-Cert-Authority, ADCS-Web-Enrollment -IncludeManagementTools
Write-Host "Configuring Certification Authority."
Install-AdcsCertificationAuthority -Force `
    -CAType EnterpriseRootCA `
    -KeyLength 2048 `
    -HashAlgorithm SHA256 `
    -CryptoProviderName "RSA#Microsoft Software Key Storage Provider" `
    -DatabaseDirectory "C:\Windows\System32\CertLog" `
    -LogDirectory "C:\Windows\System32\CertLog" `
    -OverwriteExistingKey

# Link CA to GPO

Write-Host "Exporting CA root certificate..."
# Get CA certificate from local machine store
$CAStore = Get-ChildItem Cert:\LocalMachine\CA | Where-Object { $_.Subject -like "*ws2-25-matthias-SERVER1-CA*" } | Select-Object -First 1
if (-not $CAStore) {
    Write-Host "ERROR: No CA certificate found in LocalMachine\CA store." -ForegroundColor Red
    exit 1
}

$CARootCertPath = "C:\ws2-25-matthias-SERVER1-CA_Root.cer"

# Export the CA certificate
Export-Certificate -Cert $CAStore -FilePath $CARootCertPath -Force
if (-not (Test-Path $CARootCertPath)) {
    Write-Host "ERROR: Failed to export CA root certificate." -ForegroundColor Red
    exit 1
}

Write-Host "Root certificate exported to $CARootCertPath"

# Import Group Policy module
Import-Module GroupPolicy

# GPO name
$GPOName = "Trusted Root CA Distribution"

# Get or create the GPO
$GPO = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
if (-not $GPO) {
    $GPO = New-GPO -Name $GPOName -Comment "Distributes and trusts the Enterprise Root CA"
    Write-Host "Created new GPO: $GPOName"
} else {
    Write-Host "GPO '$GPOName' already exists, using it."
}

# Path to the GPO Trusted Root store in SYSVOL
$Domain = (Get-ADDomain).DNSRoot
$GPOGUID = $GPO.Id
$PolicyStorePath = "\\$Domain\SYSVOL\$Domain\Policies\{$GPOGUID}\Machine\Microsoft\Public Key Policies\Trusted Root Certification Authorities"

# Ensure the folder exists
if (-not (Test-Path $PolicyStorePath)) {
    New-Item -Path $PolicyStorePath -ItemType Directory -Force | Out-Null
}

# Copy the CA root certificate into the GPO store
Copy-Item -Path $CARootCertPath -Destination $PolicyStorePath -Force
Write-Host "Root certificate copied to GPO Trusted Root store."

# Link GPO to the domain root
$DomainDN = (Get-ADDomain).DistinguishedName
New-GPLink -Name $GPOName -Target $DomainDN -Enforced $true
Write-Host "GPO '$GPOName' linked to domain: $DomainDN"

# Force policy update
Write-Host "Forcing Group Policy update..."
gpupdate /force
Write-Host "CA root certificate distribution via GPO completed successfully."