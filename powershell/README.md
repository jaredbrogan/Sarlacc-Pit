# PowerShell

This section of the repository will hold various tools designated for Windows Servers.

---

## Windows Update Reboot Toggle

This will disable the __*absolutely*__ awful active hours and automatic reboot that was brought about with Windows Server 2016.

Running the below commands will disable active hours permanently and make it so that the server will NOT reboot automatically once updates have been applied.

```
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name IsActiveHoursEnabled -Value 0 -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name ForcedReboot -Value 0 -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -Value 0 -Force | Out-Null
echo 5 M 15 | sconfig.cmd
```

## Disable Windows Shadow Copy

This will disable the __*terribly*__ horrible shadow copies on Windows 2012 and up servers.

Running the below commands will remove all current shadow copies, related scheduled tasks, and then reduce the shadow copy size limit to the minimum amount of 320MB.
```
Clear-Variable disk_letter -ErrorAction SilentlyContinue ; $disk_letter = New-Object System.Collections.ArrayList ; $disk_letter=(vssadmin list shadowstorage | Select-String -Pattern "volume:") -replace ".*([a-z]:).*",'$1'
for ($i=0 ; $i -lt $disk_letter.length; $i++) {vssadmin Resize ShadowStorage /For=$($disk_letter[$i]) /On=$($disk_letter[$i+1]) /MaxSize=320MB | Out-Null}
vssadmin Delete Shadows /All | Out-Null
Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {$_.TaskName -match "ShadowCopy"} | Unregister-ScheduledTask -Confirm:$false
``` 
