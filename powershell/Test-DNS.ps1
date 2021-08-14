# Will perform nslookups on the provided list of IP addresses

$InputDirectory = "$PSScriptRoot\Input\"
$LogDirectory = "$PSScriptRoot\Logs\"
$LogFile = "$LogDirectory\Results-DNS.log"

#Menu to choose the type of credential you want to create. 
function Show-Menu
{
	param 
	(
		[string]$Title = 'Menu'
	)
	cls
	Write-Host "================ $Title ================"
	Write-Host "1: Press '1' To Set Server List."
	Write-Host "2: Press '2' To Reset Server DNS Log File."
	Write-Host "3: Press '3' To Run Server DNS Check."
	Write-Host "4: Press '4' To Open Server DNS Log File."
	Write-Host "Q: Press 'Q' to quit."
}

function Run-Test
{
	Write-Host "`t`t  DNS Results"
	Write-Host "IP Address`t`t`tHostname"
	Write-Host "===================================================================="

	foreach ($ip in $file)
	{        
		$dns = (nslookup $ip | Select-String Name | Measure-Object) 2>$null
		$dnsLines= $dns.Count
		$fileLineCount = $file.Count

	if ($dnsLines -eq 1) {
		$dnsRecord = (nslookup $ip | Select-String Name 2>$null).ToString().Split(' ')[-1]
	}
	elseif ($dnsLines -eq 0) {
		$dnsRecord = "n/a"
	}
	
	Write-Output "IP Address`t`t`tDNS Record" >> $LogFile
	Write-Host "$ip`t`t`t$dnsRecord" ; Write-Output "$ip`t`t`t$dnsRecord" >> $LogFile
    }

    Write-Host "`nLog file: $LogFile"
}


## Main ##
do
{
        Show-Menu
        $UserInput = Read-Host "Select an option above"
        Switch ($UserInput)
        {
            '1'{ 
                cls
		if (Test-Path $InputDirectory -PathType Container) {
			$initialDir = "$InputDirectory";
		}
		else {
			$initialDir = "C:\";
			New-Item -ItemType directory -Path $InputDirectory | Out-Null
		}
                Add-Type -AssemblyName System.Windows.Forms
                    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
                        Multiselect = $false # Multiple files can be chosen
	                Filter =  '*.txt|*.log;*.txt' #Only certain files can be selected not working fully only can select txt files currently.
			InitialDirectory = $initialDir
                    }

                    [void]$FileBrowser.ShowDialog()

                    $file = $FileBrowser.FileName;

                    if($FileBrowser.FileNames -like "*\*") 
                    {
			# Stores output in a variable to be used.
			$file = & Get-Content $FileBrowser.FileName #Lists selected files (optional)
			Write-Host "Server List has been set successfully!"
                    }
                    else {
                        Write-Host "Cancelled by user"
                    }
               }
            '2'{ 
                cls
                
                if (Test-Path $LogFile -PathType leaf) {
			Clear-Content $LogFile
		} else {
			New-Item -ItemType directory -Force -Path $LogDirectory | Out-Null
			New-Item -ItemType file -Force -Path $LogDirectory -name Results-DNS.log | Out-Null
		}
		Write-Host "Log file has been successfully reset!"
		}
            '3'{ 
                cls
                Run-Test
               }
            '4'{ 
		cls
		Invoke-Item $LogFile
		Write-Host "Log file has been opened!"
               }
            'q'{ 
                cls
                return
               }
        }
        pause
}
until($UserInput -eq 'q')

else 
{
    Write-Host "Cancelled by user"
}