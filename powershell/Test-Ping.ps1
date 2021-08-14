#Pings Domains and Returns Ping Results, will store in log and display on completion.

$LogFile = "$PSScriptRoot\Logs\PingResults.log"

function PingTest 
{
    Write-Host "     Ping Results     "
    Write-Host "======================"

    foreach ($line in $file)
    {        
        $ping = ping -n 2 $line | FIND `"Reply`" | Measure-Object
        $pingLines= $ping.Count
        $fileLineCount = $file.Count

        if ($pingLines -ge 1)
        {
            $pingResult = "Success!"
        }
        elseif ($pingLines -eq 0)
        {
            $pingResult = "Failure..."
        }

        $line, $pingResult | Format-Table | Out-String | % {Write-Host $_}
        $line, $pingResult | Format-Table | Out-String | % {Write-Output $_ >> $LogFile} 
    }

    Write-Host "Please check $LogFile for output."
}

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
         Write-Host "2: Press '2' To Reset Server Ping Log File."
         Write-Host "3: Press '3' To Check Server Ping Results."
         Write-Host "4: Press '4' To Open Server Ping Log File."
		 Write-Host "Q: Press 'Q' to quit."
}

do
{
        Show-Menu
        $UserInput = Read-Host "Select an option above"
        Switch ($UserInput)
        {
            '1'{ 
                cls
                Add-Type -AssemblyName System.Windows.Forms
                    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
                        Multiselect = $false # Multiple files can be chosen
	                    Filter =  '*.txt|*.log;*.txt' #Only certain files can be selected not working fully only can select txt files currently.
                    }

                    [void]$FileBrowser.ShowDialog()

                    $file = $FileBrowser.FileName;

                    If($FileBrowser.FileNames -like "*\*") 
                    {
	                    # Stores output in a variable to be used.
	                    $file = & Get-Content $FileBrowser.FileName #Lists selected files (optional)
                    }

                    else {
                        Write-Host "Cancelled by user"
                    }
                Write-Host "Server List has been set successfully!"
               }
            '2'{ 
                cls
                
                if (Test-Path $PSScriptRoot\Logs\PingResults.log)
                {
                    Clear-Content $LogFile
                }
                else
                {
                    New-Item -ItemType directory -Path $PSScriptRoot\Logs\ | Out-Null
                }
                Write-Host "Log file has been successfully reset!"
               }
            '3'{ 
                cls
                PingTest
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
