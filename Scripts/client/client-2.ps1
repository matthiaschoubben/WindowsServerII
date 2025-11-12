# Variables
$DOMAIN = "ws2-25-matthias.hogent"
$USER = "Administrator"
$PASS = "vagrant"
$SECUREPASS = ConvertTo-SecureString $PASS -AsPlainText -Force
$CREDENTIAL = New-Object System.Management.Automation.PSCredential("$USER@$DOMAIN", $SECUREPASS)

# Join domain
Write-Host "Joining existing domain: $DOMAIN."
Add-Computer -DomainName $DOMAIN -Credential $CREDENTIAL -Force -Restart
Write-Output "System added to domain $DOMAIN and will restart."