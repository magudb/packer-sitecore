Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}


function Add-RDSCertificate {
    $fileName ="rds-ca-2015-root.pem"

    $url = "https://s3.amazonaws.com/rds-downloads/$fileName"
    Write-Verbose "Url to RDS certificate $url"
    $certPath = "$PSScriptRoot\$fileName"
    Write-Verbose "Temporary path for certificate file $certPath"

    Write-Output "Fetching RDS certificate from $url"

    Invoke-WebRequest -Uri $url -OutFile $certPath

    $pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2 
    $pfx.import($certPath, $null, "Exportable") 
    $store = new-object System.Security.Cryptography.X509Certificates.X509Store(
        [System.Security.Cryptography.X509Certificates.StoreName]::Root,
        "localmachine"
    )
    $store.open("MaxAllowed") 
    $store.add($certPath) 
    $store.close()

    Remove-Item $certPath -Force
} 

function Set-RightsOnFolder  {
  [CmdletBinding()]
    param(
  
	    [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
	    [string]$Path,
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
	    [string]$Account,       
        [switch]
        $Recurse
    )
    try {
        Write-Output "Changing permissions on $Path ($Recurse)"
        $acl = get-acl -path $Path
        $new = "$Account","Modify","ContainerInherit,ObjectInherit","None","Allow"
        $accessRule = new-object System.Security.AccessControl.FileSystemAccessRule $new
        $acl.SetAccessRule($accessRule)
        if($recurse){
            Get-ChildItem -Path $Path -Recurse | Set-Acl -AclObject $acl
            return
        }
        $acl | Set-Acl $Path
    }
    catch [System.Exception] {
        Write-Host $_   
    }   
}

function AddWebSite([string]$Name)
{    
    Import-Module IISAdministration   
    Import-Module WebAdministration    

    $physicalPath = "C:\Inetpub\$Name"
    Set-RightsOnFolder -Path "C:\Windows\Temp" -Account "IIS_IUSRS"   
    Set-RightsOnFolder -Path "$physicalPath\App_Data" -Account "IIS_IUSRS"  -Recurse
    Set-RightsOnFolder -Path "$physicalPath\App_Data" -Account "IIS AppPool\DefaultAppPool" -Recurse
   
    New-IISSite -Name $Name -PhysicalPath $physicalPath -BindingInformation "*:80:" 

    Invoke-Command -scriptblock {iisreset}
}
Import-Module IISAdministration   
Import-Module WebAdministration   

Remove-IISSite -Name 'Default Web Site' -Confirm:$false

$appName = "Website"
New-Item "c:\Inetpub\$appName" -type directory
Add-RDSCertificate   
AddWebSite -Name $appName

Unzip "c:\\temp\\Website.zip" "c:\Inetpub\$appName"