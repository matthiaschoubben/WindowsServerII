# WindowsServerII
Naam: Matthias Schoubben
Klasgroep: 3B2
Jaar: 2025-2026

## Deployment Guide

### Vereisten
- maak een map `sql` in de `Scripts\` map en steek hier de SQL Server 2022 Standard Edition installatie bestanden in. (te downloaden via Academic Software)
  - je zal de installatie bestanden moeten uitpakken en zorgen dat de pad overeenkomt met de pad in de server2-3.ps1 script.
  - je zal ook een `sql_config.ini` bestand moeten aanmaken in de `sql` map met volgende inhoud:
```ini
[OPTIONS]
ACTION="Install"
FEATURES=SQLENGINE
INSTANCENAME="MSSQLSERVER"
INSTANCEID="MSSQLSERVER"
SQLSVCACCOUNT="NT AUTHORITY\SYSTEM"
SQLSYSADMINACCOUNTS="BUILTIN\Administrators"
AGTSVCACCOUNT="NT AUTHORITY\SYSTEM"
SQLSVCSTARTUPTYPE="Automatic"
SECURITYMODE=SQL
SAPWD="Secure!Passw0rd"
TCPENABLED=1
BROWSERSVCSTARTUPTYPE="Automatic"
IACCEPTSQLSERVERLICENSETERMS="True"
QUIET="True"
ENU="True"
UpdateEnabled="False"
USEMICROSOFTUPDATE="False"
```
   - in deze map zal je ook de SSMS installer moeten plaatsen, deze kan je via Academic Software downloaden. Zorg zeker dat de bestandsnaam overeenkomt met de bestandsnaam in de client-3.ps1 script.

- Installeer vagrant-reload plugin op je fysieke machine:
```bash
vagrant plugin install vagrant-reload
```

### Stappenplan
1. `vagrant up` in de WindowsServerII/Scripts map
#### Server 1
2. `ssh administrator@192.168.25.10` (wachtwoord: `vagrant`)
3. `powershell`
4. `C:\Users\Public\shared_folder\server1\server1-2.ps1`
   - Na het herstarten, mogelijk dat je error krijgt met ssh verbinding maken, wachten tot het werkt.
   - Dit is normaal omdat de forest en domein aangemaakt worden.
5. `ssh administrator@192.168.25.10` (wachtwoord: `vagrant`)
6. `powershell`
7. `C:\Users\Public\shared_folder\server1\server1-3.ps1`
8. `exit`, `exit`
#### Server 2
9.   `ssh administrator@192.168.25.20` (wachtwoord: `vagrant`)
10.   `powershell`
11.   `C:\Users\Public\shared_folder\server2\server2-2.ps1`
12.   `ssh administrator@192.168.25.20` (wachtwoord: `vagrant`)
13.   `powershell`
14.   `C:\Users\Public\shared_folder\server2\server2-3.ps1` (dit kan even duren)
15.   `exit`, `exit`
#### Client 1
16.   via VirtualBox inloggen op client met vagrant/vagrant
17.   Powershell als administrator openen
18.   `C:\vagrant\client\client-1.ps1`
19.   restarten
20.   `C:\Users\Public\shared_folder\client\client-2.ps1`
21.   inloggen met Other User -> administrator@ws2-25-matthias (wachtwoord: vagrant)
22.   `C:\Users\Public\shared_folder\client\client-3.ps1` (dit kan even duren)

### Gebruikers / Wachtwoorden
Server1:
| Gebruiker     | Wachtwoord |
| ------------- | ---------- |
| administrator | vagrant    |
| vagrant       | vagrant    |

Server2:
| Gebruiker     | Wachtwoord |
| ------------- | ---------- |
| administrator | vagrant    |
| vagrant       | vagrant    |

Client:
| Gebruiker     | Wachtwoord |
| ------------- | ---------- |
| administrator | vagrant    |
| vagrant       | vagrant    |

Binnen het domein:
| Gebruiker                     | Wachtwoord |
| ----------------------------- | ---------- |
| administrator@ws2-25-matthias | vagrant    |
| matthias                      | Pass@123   |
| gilles                        | Pass@123   |
| messi                         | Pass@123   |
| ronaldo                       | Pass@123   |


## Project Status

### Wat werkt / niet
Opbasis van de Checklist
- [x] DC
- [x] DNS
- [x] DHCP
- [ ] CA
   - [x] Management tools
   - [ ] root certificaat wordt getoond
   - [ ] Client vertrouwt root certificaat
   - [ ] Web enrollment werkt
- [ ] SQL
  - [x] SSMS op client
  - [x] Client kan inloggen
  - [x] Inloggen met sa
  - [ ] Inloggen met domeingebruiker
  - [x] Database aanmaken
- [x] Firewall
- [x] Algemeen verbindingen

### Problemen en oplossingen
- SQL server installatie werkt niet met iso bestand, setup.exe could not be found
  - oplossing: bestanden uitpakken in gedeelde map
  - moest manueel ini bestand aanmaken
- Vagrant provisioning:
  - poging gemaakt maar meerdere problemen:
    - crash na server1-2.ps1
    - crash na client-1.ps1
    - server2 nog niet voldoende getest
  - Oplossing: manueel uitvoeren van de scripts na vagrant up
- DNS verbinding van client naar servers
  - Error bij het verbinden met de servers via server manager
  - Opmerking: nslookup werkt ook niet
    - NAT interface kreeg prioriteit over host-only interface -> verkeerde DNS server gebruikt
  - Oplossing: prioriteit van de interfaces aanpassen
- CA:
  - GPO
    - De gpo wou niet toepassen op de client
    - Verschillende oplossingen geprobeerd, maar niet gelukt om op te lossen
  - 403 error bij aanmelden webpagina
    - Geen toegang
    - Mogelijke oplossing:
      ```ps1
      Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -Name enabled -Value true -Location "Default Web Site/certsrv"
      Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name enabled -Value true -Location "Default Web Site/certsrv"
      Set-WebConfigurationProperty -Filter "/system.webServer/security/access" -Name sslFlags -Value "None" -Location "Default Web Site/certsrv"
      ```
- SQL manager gebruiken als niet admin gebruiker
  - Geen verbinding mogelijk, niet toegelaten

## Conclusie
   Tijdens dit project heb ik veel bijgeleerd over het opzetten en configureren van een Windows Server omgeving met verschillende rollen zoals Active Directory, DNS, DHCP, Certificate Authority en SQL Server. Ik kwam hier vorige jaren in aanraking met tijdens Windows Server I en SEP, maar dit project gaf me de kans om deze kennis verder uit te diepen en toe te passen in een praktische context. Het opzetten van de Vagrant omgeving en het schrijven van PowerShell scripts om de verschillende servers en clients te configureren, was een waardevolle ervaring die mijn vaardigheden in automatisering en scripting heeft verbeterd.
   Als ik dit project opnieuw zou doen, zou ik meer tijd besteden aan het testen en debuggen van de provisioning scripts om ervoor te zorgen dat alles soepel verloopt zonder handmatige tussenkomst. Daarnaast zou ik ook meer aandacht besteden aan de Certifcate Authority configuratie, aangezien ik hier enkele uitdagingen tegenkwam die ik niet volledig heb kunnen oplossen binnen de tijdsperiode van het eerste deel van het project. Over het algemeen ben ik tevreden met wat ik heb bereikt en kijk ik ernaar uit om deze kennis toe te passen in toekomstige projecten.
   Ik denk dat ik de meeste tijd verloren heb aan het oplossen van het probleem met de GPO voor de Certificate Authority en het debuggen van de provisioning scripts. Om de provisioning te test durde langer dan verwacht, vooral bij de client. In het algemeen heb ik niet te veel tijd verloren aan onvoorziene problemen, maar sommige configuraties namen meer tijd in beslag dan ik had verwacht.