<#
.SYNOPSIS
    This script facilitates the process of verifying Active Directory credentials are still valid.

.DESCRIPTION
    Using this script will allow users to validate Active Directory user credentials.

    Options are as follows:
     -UserName : The user you will authenticate with against the domain controller. [REQUIRED]

	 -Password : The password tied to the user's login credentials. [REQUIRED]
	          - If specified on command line, the password will be in plaintext.
	          - If inputed after script execution, the password will be encrypted.

	 -Domain : The LDAP domain that the user will be authenticated against.
	          - Unless specified on the command line, this will default to your current Active Directory domain.

.EXAMPLE
    Test-ADCreds.ps1

.EXAMPLE
    Test-ADCreds.ps1 -UserName AZ012345 -Domain contoso.com

.LINK
    https://github.com/jaredbrogan/Sarlacc-Pit/powershell

.NOTES
    Author:  Jared Brogan
    Contact: https://github.com/jaredbrogan
#>

param(
[Parameter(Mandatory=$true)][string]$UserName,
[Parameter(Mandatory=$true)][Security.SecureString]$Password,
[string]$Domain=$null)

$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
$PlaintextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

if ( $Domain -eq "" ) {
	$Domain = (Get-WmiObject Win32_ComputerSystem).Domain
}
else {
	$Domain = $Domain.ToLower()
}

Function Test-ADAuthentication {
    param(
        $domain,
		$username,
        $password)
    
    (New-Object DirectoryServices.DirectoryEntry "LDAP://$domain","$username","$password").psbase.name -ne $null
}

$check_creds = Test-ADAuthentication -domain $Domain -username $UserName -password $PlaintextPassword
Write-Host
if ( $check_creds -eq $true ) {
	Write-Host "$Domain\$UserName's credentials are valid!"
}
elseif ( $check_creds -eq $false ) {
	Write-Host "$Domain\$UserName's credentials are NOT valid..."
}
else {
	Write-Host "Undetermined error"
}
