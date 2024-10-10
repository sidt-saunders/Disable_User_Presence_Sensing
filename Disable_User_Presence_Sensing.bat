@ECHO OFF
SET ThisScriptsDirectory=\\USALPLATP01\DropBox\Sidt_Saunders\Scripts\Script_Files\Disable_User_Presence_Sensing\
SET PowerShellScriptPath=%ThisScriptsDirectory%Disable_User_Presence_Sensing.ps1
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%PowerShellScriptPath%""' -Verb RunAs}";