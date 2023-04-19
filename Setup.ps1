$ProgressPreference = 'SilentlyContinue'
$InstallDir = "C:\AWSG5CloudGamingSetup"
New-Item $InstallDir -ItemType directory

$Header = @"
AWS EC2 Cloud Gaming Basic Setup
By chongkwongsheng (https://github.com/chongkwongsheng/g5-cloudrig-lite/)
Forked from tomgrice (https://github.com/tomgrice/g5-cloudrig/)
Original work by acceleration3 (https://github.com/acceleration3)
"@

# Get initial settings from user.

Write-Host "$Header" -ForegroundColor DarkMagenta
Write-Host "Before we start, just a few questions..." -ForegroundColor Green
$AdminPassword = $null
do {
    if($null -ne $AdminPassword) { Write-Host "Passwords do not match." -ForegroundColor Red }
    $AdminPassword_Secure = Read-Host "What would you like to set as the administrator password?" -AsSecureString
    $AdminPasswordConfirm_Secure = Read-Host "Confirm administrator password" -AsSecureString
    $AdminPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword_Secure))
    $AdminPasswordConfirm = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPasswordConfirm_Secure))
} while ($AdminPassword -ne $AdminPasswordConfirm)

# Disable Windows password complexity
Write-Host "Disabling Windows password complexity" -ForegroundColor Cyan
secedit /export /cfg c:\secpol.cfg
(Get-Content C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
Remove-Item -Force c:\secpol.cfg -Confirm:$False

# Set Administrator password to user input
Start-Process net -ArgumentList "user", "Administrator", $AdminPassword -NoNewWindow -Wait

# Disable Local User Access control
Write-Host "Disabling Local User Access control" -ForegroundColor Cyan
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA -Value 0 -Force

function Set-PriorityControl {
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38
    Write-Host "PriorityControl set to Programs." -ForegroundColor Green
}

function Set-BestAppearance {
    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
    try {
        $s = (Get-ItemProperty -ErrorAction stop -Name VisualFXSetting -Path $path).VisualFXSetting 
        if ($s -ne 1) {
            Set-ItemProperty -Path $path -Name 'VisualFXSetting' -Value 1
        }
    }
    catch {
        New-ItemProperty -Path $path -Name 'VisualFXSetting' -Value 1 -PropertyType 'DWORD'
    }
   
}

Write-Host "Configuring Windows performance tweaks." -ForegroundColor Cyan
Set-PriorityControl
Set-BestAppearance

# Audio fix
Write-Host "Fixing audio." -ForegroundColor Cyan
New-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "ServicesPipeTimeout" -Value 600000 -PropertyType "DWord" | Out-Null
Set-Service -Name Audiosrv -StartupType Automatic

# Disable Shutdown Tracker
Write-Host "Disabling shutdown tracker" -ForegroundColor Cyan
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" | New-ItemProperty -Name ShutdownReasonOn -Value 0

if (-Not (Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Reliability'))
{
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT' -Name Reliability -Force
}

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Reliability' -Name ShutdownReasonOn -Value 0
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Reliability' -Name ShutdownReasonUI -Value 0

# Install Chocolatey
Write-Host "Installing chocolatey package manager" -ForegroundColor Cyan
Invoke-RestMethod -Uri 'https://community.chocolatey.org/install.ps1' | Invoke-Expression

# Install pwsh 7 (Core)
Write-Host "Installing Powershell Core" -ForegroundColor Cyan
choco install powershell-core -y

$enable_autologon = $Host.UI.PromptForChoice("Steam", "Would you like to enable autologon?", ('&Yes', '&No'), 0)
if ($enable_autologon -eq 0) {
    # Set up Windows AutoLogon
    Write-Host "Setting up auto logon." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://live.sysinternals.com/Autologon.exe" -OutFile "$InstallDir\Autologon.exe"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableCAD" -Value 1
    Start-Process "$InstallDir\Autologon.exe" -ArgumentList "Administrator", ".\", $AdminPassword, "/accepteula" -NoNewWindow -Wait
}

$install_wireguard = $Host.UI.PromptForChoice("7zip", "Would you like to install Wireguard?", ('&Yes', '&No'), 0)
if ($install_wireguard -eq 0) {
    choco install wireguard -y
}

$install_7zip = $Host.UI.PromptForChoice("7zip", "Would you like to install 7zip?", ('&Yes', '&No'), 0)
if ($install_7zip -eq 0) {
    choco install 7zip -y
}

$install_steam = $Host.UI.PromptForChoice("Steam", "Would you like to install Steam?", ('&Yes', '&No'), 0)
if ($install_steam -eq 0) {
    choco install steam -y
}

$install_sunshine = $Host.UI.PromptForChoice("Sunshine", "Would you like to download Sunshine (Open Source NVIDIA GameStream)? Installation required.", ('&Yes', '&No'), 0)
if ($install_sunshine -eq 0) {
    Invoke-WebRequest -Uri "https://github.com/LizardByte/sunshine/releases/latest/download/sunshine-windows-installer.exe" -OutFile "$InstallDir\sunshine-windows-installer.exe"
}

$install_razer = $Host.UI.PromptForChoice("Razer", "Would you like to download Razer Surround Drivers? Installation required.", ('&Yes', '&No'), 0)
if ($install_razer -eq 0) {
    Invoke-WebRequest -Uri "http://rzr.to/surround-pc-download"  -OutFile "$InstallDir\razer-surround-driver.exe"
}

$install_nvidiagamingdrivers = $Host.UI.PromptForChoice("NVIDIA", "Would you like to install NVIDIA vGaming Drivers?", ('&Yes', '&No'), 0)
if ($install_nvidiagamingdrivers -eq 0) {
    $NVDriverURL = "https://nvidia-gaming.s3.amazonaws.com/" + (Invoke-RestMethod "https://nvidia-gaming.s3.amazonaws.com/?prefix=windows/latest").ListBucketResult.Contents.Key[1]
    Invoke-WebRequest $NVDriverURL -OutFile "$InstallDir\NVDriver.zip"
    Expand-Archive -Path "$InstallDir\NVDriver.zip" -DestinationPath "$InstallDir\NVDriver" -Force
    Start-Process "$InstallDir\NVDriver\*Cloud_Gaming*server2022*.exe" -ArgumentList "-s" -NoNewWindow -Wait
    New-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global" -Name "vGamingMarketplace" -PropertyType "DWord" -Value "2"
    Invoke-WebRequest -Uri "https://nvidia-gaming.s3.amazonaws.com/GridSwCert-Archive/GridSwCertWindows_2021_10_2.cert" -OutFile "$Env:PUBLIC\Documents\GridSwCert.txt"
}

$do_restart = $Host.UI.PromptForChoice("Restart required", "Would you like to restart Windows now?", ('&Yes', '&No'), 0)
if ($do_restart -eq 0) {
    shutdown /r /t 0
}

Write-Host "Script complete." -ForegroundColor Green
Pause
