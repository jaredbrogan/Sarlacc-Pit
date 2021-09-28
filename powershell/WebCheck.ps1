<#
.SYNOPSIS
    This script facilitates the process of checking a website's contents, which then stores it and its checksum.

.DESCRIPTION
    Using this script will streamline the process of a user to gather a website's contents and checksum.
    Both items will be stored on the user's Desktop in a folder named "WebCheck".

    Options are as follows:
     -URL : The web address of the desired site you wish to check. [REQUIRED]

     -Port : The port of the website you want to check against. If not specified, '443' will be the default value. [Optional]

.EXAMPLE
    WebCheck.ps1 -URL website.com

.EXAMPLE
    WebCheck.ps1 -URL google.com -Port 443

.LINK
    https://github.com/jaredbrogan/Sarlacc-Pit/tree/main/powershell/WebCheck.ps1

.NOTES
    Author:  Jared Brogan
    Contact: jaredbrogan@gmail.com
#>

param(
	[Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string]$URL,
	[UInt16]$Port='443'
)

process {
    Clear ; Write-Host ""
    #Defaults
    $ProgressPreference = 'SilentlyContinue'
    $PSDefaultParameterValues['Test-NetConnection:InformationLevel'] = 'Quiet'

    # Variable cleanup and pre-validation
	$URL = $URL.ToLower()
	$URL = $URL -replace "http.*://" -replace "http.*://"
    $URL = $URL -replace ":.*" -replace ".*:"

    $UserDesktop = [Environment]::GetFolderPath("Desktop")
    $LogPath = "${UserDesktop}\WebCheck"
    New-Item -Path "$LogPath" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    $checkURL = Test-NetConnection $URL -Port $Port -ErrorAction Ignore

    Write-Host -NoNewLine "Checking ${URL} on port $Port... "
	if ( $Port -eq 443 ) {
        if ( $checkURL -eq "True" ) {
		    Invoke-WebRequest -Uri "https://${URL}" -TimeoutSec 5 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Content | Out-File -FilePath "${LogPath}\${URL}_${Port}-content.txt"
	    }
        else {
            Write-Host "ERROR!"
            Write-Host "`tUnable to establish a reliable connection to the specified URL. Exiting...`n"
            exit
        }
    }
	else {
		Invoke-WebRequest -Uri "http://${URL}:${Port}" -TimeoutSec 5 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Content | Out-File -FilePath "${LogPath}\${URL}_${Port}-content.txt"
	}
    Get-FileHash "${LogPath}\${URL}_${Port}-content.txt" | Out-File "${LogPath}\${URL}_${Port}-checksum.txt"
    Write-Host "Complete!`n"

    Write-Host "Files generated can be found here`n`t• ${LogPath}\${URL}_${Port}-content.txt`n`t• ${LogPath}\${URL}_${Port}-checksum.txt`n"
}
