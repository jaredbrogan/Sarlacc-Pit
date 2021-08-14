param([string]$domain=$env:userdomain,[Parameter(Mandatory=$true)][string]$user)
$domain = $domain.ToUpper()
$user = $user.ToUpper()

$user_login=Get-Process -IncludeUserName | Select-Object UserName | Where-Object { $_.UserName -ne $null -and $_.UserName.StartsWith("$domain\$user") } | Measure-Object | %{$_.Count}
if ($user_login -eq 0)
{
   Write-Host "OFFLINE"
   Start-Sleep 1
   exit
}
else
{
    Write-Host "ONLINE"
    Start-Sleep 1
    exit
}
