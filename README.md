# g5-cloudrig-lite
Basic Powershell script to set up cloud gaming on Amazon EC2 G5 instances. The script does the following:
1. Asks for a new administrator password
1. Disables Local User Access control
1. Disables shutdown tracker
1. Optimizes a few Windows settings
1. Installs package manager Chocolatey
1. Installs Powershell Core

Optional
1. Sets up autologon
1. Installs Wireguard
1. Installs 7-zip
1. Installs Steam
1. Downloads Sunshine (Installation required)
1. Downloads Razer Surround audio drivers (Installation required)
1. Installs and registers NVIDIA gaming drivers for Windows Server 2022

Run this command in an elevated Powershell terminal:
```
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/chongkwongsheng/g5-cloudrig-lite/main/Setup.ps1'))
```
