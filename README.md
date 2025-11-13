# WindowsServerII
Naam: Matthias Schoubben
Klasgroep: 3B2


# Notes
sql_config.ini manueel aanmaken en instellen
install vagrant-reload plugin
 
## Deployment Guide

### Vereisten

### Stappenplan
1. `vagrant up` in de WindowsServerII/Scripts map
#### Server 1
2. `ssh administrator@192.168.25.10` (wachtwoord: `vagrant`)
3. `powershell`
4. `C:\Users\Public\shared_folder\server1\server1-2.ps1`
   1. Na het herstarten, mogelijk dat je error krijgt met ssh verbinding maken, wachten tot het werkt (max 15 min).
   2. Dit is normaal omdat de forest en domein aangemaakt worden.
5. `ssh administrator@192.168.25.10` (wachtwoord: `vagrant`)
6. `powershell`
7. `C:\Users\Public\shared_folder\server1\server1-3.ps1`
8. `exit`, `exit`
#### Server 2
1.  `ssh administrator@192.168.25.20` (wachtwoord: `vagrant`)
2.   `powershell`
3.   `C:\Users\Public\shared_folder\server2\server2-2.ps1`
4.   `ssh administrator@192.168.25.20` (wachtwoord: `vagrant`)
5.   `powershell`
6.   `C:\Users\Public\shared_folder\server2\server2-3.ps1` (dit kan even duren)
7.   `exit`, `exit`
#### Client 1
1.   via VirtualBox inloggen op client met vagrant/vagrant
2.   Powershell als administrator openen
3.   `C:\vagrant\client\client-1.ps1`
4.   restarten
5.   `C:\Users\Public\shared_folder\client\client-2.ps1`
6.   inloggen met Other User -> administrator@ws2-25-matthias (wachtwoord: vagrant)
7.   `C:\Users\Public\shared_folder\client\client-3.ps1` (dit kan even duren)

### Gebruikers / Wachtwoorden

## Project Status

## Conclusie
