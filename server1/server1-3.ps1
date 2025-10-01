# Varibles
Write-Host "Setting varibles."
$GW = "192.168.25.1"
$IP = "192.168.25.11"
$IP2 = "192.168.25.21"
$RANGE = "192.168.25.0"
$REVERSE = "25.168.192.in-addr.arpa"
$NAME = "ws2-2425-simon.hogent"
$ISO = "C:\Users\administrator\shared_folder\en_sql_server_2019_standard_x64_dvd_814b57aa.iso"
$PathToAdd = "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\"
$CurrentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

# Authorize DHCP server in AD
Write-Output "Authorizing DHCP Server in the domain controller."
Add-DhcpServerInDC -DnsName $NAME -IPAddress $IP
Write-Output "DHCP server autorized successfully."

# Configure DHCP
Write-Host "Configuring DHCP."
Add-DhcpServerv4Scope -Name "IPScope" -StartRange "192.168.24.101" -EndRange "192.168.24.150" -SubnetMask "255.255.255.0" -State Active
Add-DhcpServerv4ExclusionRange -ScopeId $RANGE -StartRange "192.168.24.151" -EndRange "192.168.24.200"
Set-DhcpServerv4OptionValue -ScopeId $RANGE -OptionId 3 -Value $GW
Set-DhcpServerv4OptionValue -ScopeId $RANGE -OptionId 6 -Value $IP,$IP2
Set-DhcpServerv4OptionValue -ScopeId $RANGE -OptionId 15 -Value $NAME
Write-Output "DHCP configuration completeed sucessfully."

# Configure DNS
Write-Host "Configuring DNS and records."
Add-DnsServerPrimaryZone -NetworkId $RANGE/24 -ZoneFile $REVERSE".DNS" -DynamicUpdate none
Write-Output "Reverse lookup zone $REVERSE created."

# Add A record for server1
Add-DnsServerResourceRecordA -Name "server1" -ZoneName $NAME -IPv4Address $IP
Write-Host "DNS A record for server1 added."
# Add PTR record for server1
Add-DnsServerResourceRecordPtr -Name "11" -ZoneName $REVERSE -PtrDomainName "server1.$NAME"
Write-Host "DNS PTR record for server1 added."
# Add A record for server2
Add-DnsServerResourceRecordA -Name "server2" -ZoneName $NAME -IPv4Address $IP2
Write-Host "DNS A record for server2 added."
# Add PTR record for server2
Add-DnsServerResourceRecordPtr -Name "21" -ZoneName $REVERSE -PtrDomainName "server2.$NAME"
Write-Host "DNS PTR record for server2 added."

# Configuring zone transfers using dnscmd
Write-Host "Configuring zone transferrs with dnscmd."
dnscmd /ZoneResetSecondaries $NAME /SecureList $IP2
dnscmd /ZoneResetSecondaries $REVERSE /SecureList $IP2
Write-Output "Zone transfers configred."

# Configure OU
Write-Output "Configuring OU and user account."
Import-Module ActiveDirectory
    New-ADOrganizationalUnit -Name "gebruikers" -ProtectedFromAccidentalDeletion $false
    Write-Host "Organizational Unit 'gebruikers' created."

    New-ADOrganizationalUnit -Name "Workstations" -ProtectedFromAccidentalDeletion $false
    New-ADOrganizationalUnit -Name "PCs" -ProtectedFromAccidentalDeletion $false -Path "OU=Workstations, DC=ws2-2425-simon, DC=hogent"

# Configure users
Write-Host "Add users to the OU."
$GEBRUIKERS = Import-Csv "C:\Users\administrator\shared_folder\gebruikers.csv" -Delimiter ";"

foreach ($GEBRUIKER in $GEBRUIKERS) {
    $FIRSTNAME = $GEBRUIKER.Voornaam
    $LASTNAME = $GEBRUIKER.Achternaam
    $INITIALS = $GEBRUIKER.Initialen
    $USERNAME = $GEBRUIKER.Gebruikersnaam
    $PASSWORD = $GEBRUIKER.Password
    $OU = $GEBRUIKER.OU


if (-not (Get-ADUser -F { SamAccountName -eq $USERNAME })) {
    New-ADUser `
        -SamAccountName $USERNAME `
        -UserPrincipalName "$USERNAME@$NAME" `
        -Name "$FIRSTNAME $LASTNAME" `
        -GivenName "$FIRSTNAME" `
        -Surname "$LASTNAME" `
        -Displayname "$FIRSTNAME $LASTNAME" `
        -AccountPassword (ConvertTo-SecureString $PASSWORD -AsPlainText -Force) -ChangePasswordAtLogon $False `
        -Path $OU `
        -Enabled $true
    Write-Output "User '$USERNAME' created sucessfully."
} else {
    Write-Host "User '$USERNAME' already exists."
}
}