# WindowsServerII

# Notes
sql_config.ini manueel aanmaken en instellen
 
## Stappenplan
1. `vagrant up` in de WindowsServerII map
2. via VirtualBox inloggen op server1
3. server1-1.ps1
4. `ssh vagrant@192.168.25.10` (wachtwoord: `vagrant`)
5. `powershell`
6. server1-2.ps1
7. `ssh Administrator@192.168.25.10` (wachtwoord: `vagrant`)
8. server1-3.ps1
9. `exit`, `exit`
10. `ssh vagrant@192.168.25.20` (wachtwoord: `vagrant`)
11. `powershell`
12. server2-1.ps1
13. server2-2.ps1
14. `ssh Administrator@192.168.25.20` (wachtwoord: `vagrant`)
15. server2-3.ps1
16. `exit`, `exit`
17. via VirtualBox inloggen op client
18. client1-1.ps1
19. client1-2.ps1