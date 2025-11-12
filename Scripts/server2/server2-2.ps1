# Join Domain

# Variables
$DOMAIN = "ws2-25-matthias.hogent"
$USERNAME = "Administrator"
$PASSWORD = "vagrant"
$SECUREPASS = ConvertTo-SecureString $PASSWORD -AsPlainText -Force
$CREDENTIAL = New-Object System.Management.Automation.PSCredential("$USERNAME@$DOMAIN", $SECUREPASS)

# Join domain
Write-Host "Joining the existing domain: $DOMAIN."
Add-Computer -DomainName $DOMAIN -Credential $CREDENTIAL -Force -Restart
Write-Output "Succesfully joined the domain. The system will now restart."