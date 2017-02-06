Add-Type -AssemblyName System.IO.Compression.FileSystem
Import-Module IISAdministration   
Import-Module WebAdministration 
function Unzip {
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

function AddWebSite([string]$Name) { 
    $physicalPath = "C:\Inetpub\$Name" 
  
    New-IISSite -Name $Name -PhysicalPath $physicalPath -BindingInformation "*:80:" 

    Invoke-Command -scriptblock {iisreset}
}
  

Remove-IISSite -Name 'Default Web Site' -Confirm:$false

$appName = "Website"
New-Item "c:\Inetpub\$appName" -type directory
Add-RDSCertificate   
AddWebSite -Name $appName

Unzip "c:\\temp\\Website.zip" "c:\Inetpub\$appName"