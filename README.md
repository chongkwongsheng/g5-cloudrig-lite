# g5-cloudrig-lite
Basic Powershell script to set up cloud gaming on Amazon EC2 G5 instances. The script does the following:
1. Asks for a new administrator password
1. Optimizes a few Windows settings
1. Disables Local User Access control
1. Disables shutdown tracker
1. Sets up autologon
1. Installs package manager Chocolatey
1. Installs 7-zip
1. Installs Steam

Run this command in an elevated Powershell terminal:
```
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/tomgrice/g5-cloudrig-lite/main/Setup.ps1'))
```
