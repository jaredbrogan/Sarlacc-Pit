Clear
Write-Host -NoNewLine "Enabling Print Spooler service... "
Set-Service -Name 'Spooler' -Status Running -StartupType Manual
Write-Host "Complete!`n"
Start-Sleep 2

Write-Host ""

$limit = 61
for ($i = 1; $i -le $limit; $i++ )
{
    $countdown = $limit - $i
    Write-Progress -Activity "You have $($limit - 1) seconds until the Print Spooler service is disabled" -Status "$countdown seconds remaining..." -PercentComplete ((($i) /  $limit) * 100)
    Start-Sleep 1
}
Write-Progress -Activity "You have $($limit - 1) seconds until the Print Spooler service is disabled" -Status "Ready" -Complete

Write-Host -NoNewline "Time limit reached. Disabling Print Spooler service... "
Stop-Service -Name 'Spooler' -Force ; Set-Service -Name 'Spooler' -StartupType Disabled
Write-Host "Complete!`n"
Start-Sleep 5
