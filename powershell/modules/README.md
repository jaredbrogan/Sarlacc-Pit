## Manual Instructions
 - Copy and paste the desired module's zipped folder into this directory: C:\Windows\System32\WindowsPowerShell\v1.0\Modules
 - Extract contents into the same directory, being sure to remove the zipped folder afterwards.
 - PowerShell should now allow the module to be called successfully going forward.
   - You may need to open a new PowerShell session before the module can be called.

---

## Automated Instructions

```
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri https://raw.githubusercontent.com/jaredbrogan/Sarlacc-Pit/main/powershell/modules/PSWindowsUpdate.zip -OutFile 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules\PSWindowsUpdate.zip'
Expand-Archive -LiteralPath 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules\PSWindowsUpdate.zip' -DestinationPath 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules\'
Remove-Item 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules\PSWindowsUpdate.zip'
Clear ; Invoke-Command { & "powershell.exe" } -NoNewScope
```
