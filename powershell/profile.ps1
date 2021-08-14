$Desktop = [Environment]::GetFolderPath("Desktop")
Set-Location $Desktop;
Set-PSReadlineOption -BellStyle None;
$host.ui.RawUI.WindowTitle="BroBro Command Center";
#$host.ui.RawUI.BackgroundColor = "Black";
#$host.ui.RawUI.ForegroundColor = "Red"
$colors = $host.privatedata

function prompt            
{            
    "PS " + $(get-location) + " [$(Get-Date -Format F)]> "            
}