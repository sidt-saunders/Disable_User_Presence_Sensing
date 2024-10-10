#This script is to disable that annoying security feature called User Presence Sensing
#This script will check if the device has the feature available and then disable it

#----------
#Variables
#----------

$FailCounter = 0

#----------
#Functions
#----------

Function NotValidSelectionComputerRestart() {
    Write-Host "`nPlease enter a valid selection." -ForegroundColor DarkRed
    ComputerRestart
}

Function ScriptExit() {
    Write-Host "`nToo many failed attempts. Script will exit in 5 seconds.`n" -ForegroundColor DarkRed
    Start-Sleep -Seconds 5
    Exit
}

Function ComputerRestart() {
    Write-Host "`nThis device needs to be restarted for the setting to take effect.`nPlease confirm you would like to restart (Y/N):" -ForegroundColor DarkYellow
    $ConfirmRestart = Read-Host
    If ($ConfirmRestart -eq "n" -or $ConfirmRestart -eq "N") {
        Write-Host "`nPlease restart as soon as possible for the changes to take effect.`nThe script will exit in 5 seconds.`n" -ForegroundColor DarkRed
        RemoveGetBIOSModule
        Start-Sleep -Seconds 5
        Exit
    }
    If ($ConfirmRestart -eq "y" -or $ConfirmRestart -eq "Y") {
        Write-Host "`nThis device will restart in 30 seconds." -ForegroundColor DarkGreen
        RemoveGetBIOSModule
        Start-Sleep -Seconds 30
        Restart-Computer -Force
    }
    Else {
        While ($FailCounter -ne 2) {
            $FailCounter++
            NotValidSelectionComputerRestart
        }
        $FailCounter = 0
        ScriptExit
    }
}

Function GetBIOSPassword() {
    #Prompt for BIOS Password
    $BIOSPassSecure = Read-Host "Please enter the BIOS password " -AsSecureString

    #Convert to "insecure" string
    $BIOSPassConvert = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($BIOSPassSecure)
    $BIOSPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BIOSPassConvert)

    #Clear out unmanaged memory
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BIOSPassConvert)

    #Not sure why VSCodium is still telling me that $BIOSPass is assigned but never used, so I am adding this line
    $BIOSPass | Out-Null
}

Function NuGetPackage() {
    #Check if NuGet is installed
    $IsNuGetInstalled = Find-PackageProvider -Name "NuGet" 2>$null

    #If not installed, install v2.8.5.208, which is the newest version as of 2024/09/23
    #I also cannot get the prompt to be bypassed, but I am leaving the -Force in, and hoping that Register-PSRepository will work
    If ($null -eq $IsNuGetInstalled) {
        Write-Host "`nPlease wait while NuGet is installed.`n" -ForegroundColor DarkGreen
        Start-Sleep -Seconds 2
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.208 -Force
        Register-PSRepository -Default
    }
    Else {
        Write-Host "`nNuGet is already installed`n" -ForegroundColor DarkGreen
        Start-Sleep -Seconds 2
    }
}

Function GetBIOSModule() {
    #Check if GetBIOS is installed
    $IsGetBIOSInstalled = Get-InstalledModule -Name "GetBIOS" 2>$null

    #If not installed, install bypassing confirmation.
    #Surprisingly, I got this one to work fine with -Force
    If ($null -eq $IsGetBIOSInstalled) {
        Write-Host "`nPlease wait while GetBIOS module is being installed.`n" -ForegroundColor DarkGreen
        Start-Sleep -Seconds 2
        Install-Module GetBIOS -Force
    }
    Else {
        Write-Host "`nGetBIOS is already installed`n" -ForegroundColor DarkGreen
        Start-Sleep -Seconds 2
    }
}

Function DisableUserPresenceSensing() {
    Write-Host "`nDisabling User Presence Sensing and saving settings to the BIOS.`n" -ForegroundColor DarkGreen
    Start-Sleep -Seconds 2
    #Disable User Presence Sensing
    $ModBIOS = Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi
    $ModBIOS.SetBiosSetting("UserPresenceSensing,Disable,$BIOSPass,ascii,us")
    #Save changes to BIOS
    $SaveBIOS = Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi
    $SaveBIOS.SaveBiosSettings("$BIOSPass,ascii,us")
    Write-Host "`nUser Presence Sensing has been disabled.`n" -ForegroundColor DarkGreen
}

Function RemoveGetBIOSModule() {
    #Uninstall GetBIOS Module
    Write-Host "Uninstalling GetBIOS`n" -ForegroundColor DarkGreen
    Uninstall-Module GetBIOS
}

Function CheckUserPresenceSensingDisabled() {
    #Check if UserPresenceSensing is disabled
    $UPSDisableCheck = (Get-BIOS | Where-Object {$_.Setting -eq "UserPresenceSensing"}).Value

    #If disabled, that's good
    If ($UPSDisableCheck -eq "Disable") {
        Write-Host "`nUser Presence Sensing is already disabled on this device.`nScript will exit in 5 seconds.`n`n" -ForegroundColor DarkGreen
        Start-Sleep -Seconds 5
        Exit
    }
    #If enabled, run everything!
    Else {
        GetBIOSPassword
        DisableUserPresenceSensing
        RemoveGetBIOSModule
        ComputerRestart
    }
}

Function NotValidSelectionConfirmSelection() {
    Write-Host "`nPlease enter a valid selection. Please try again.`n" -ForegroundColor DarkRed
    ConfirmSelection
}

Function ConfirmSelection() {
    #Confirm if user wants to go through this
    Write-Host "`nPlease confirm you would like to run this script (Y/N)"
    $SwitchSelect = Read-Host
    If ($SwitchSelect -eq "n" -or $SwitchSelect -eq "N") {
        Write-Host "`nNo changes have been made.`nScript will exit in 5 seconds.`n" -ForegroundColor DarkGreen
        Start-Sleep -Seconds 5
        Exit
    }
    If ($SwitchSelect -eq "y" -or $SwitchSelect -eq "Y") {
        Write-Host "`nPlease save all your work before continuing.`n" -ForegroundColor DarkRed
        Start-Sleep -Seconds 5
        Write-Host "`nScript will start in 5 seconds." -ForegroundColor DarkRed
        Write-Host "Press CTRL+C to abort script at any time`n" -ForegroundColor DarkGreen
        CheckUserPresenceSensingDisabled
    }
    Else {
        While ($FailCounter -ne 2) {
            $FailCounter++
            NotValidSelectionConfirmSelection
        }
        $FailCounter = 0
        ScriptExit
    }
}

Function UserPresenceSensingAvailable() {
    #Check if UserPresenceSensing exists
    $UPSExists = (Get-BIOS | Where-Object {$_.Setting -eq "UserPresenceSensing"}).Setting

    #If the setting does not exist, exit the script
    If ($null -eq $UPSExists) {
        Write-Host "`nThis Lenovo device does NOT have User Presence Sensing.`nNo changes have been made.`n`nScript will exit in 5 seconds.`n" -ForegroundColor DarkGreen
        RemoveGetBIOSModule
        Start-Sleep -Seconds 5
        Exit
    }
    Else {
        ConfirmSelection
    }
}

#----------
#Script
#----------

Clear-Host

Write-Host "`nThis script will disable User Presence Sensing on your device, if available." -ForegroundColor DarkGreen
Write-Host "`nNOTE: The device needs to be restarted before the changes take effect.`n" -ForegroundColor DarkYellow
Start-Sleep -Seconds 2
#Before checking if User Presence Sensing is available, need to check if NuGet and Get-BIOS are installed
NuGetPackage
GetBIOSModule
UserPresenceSensingAvailable