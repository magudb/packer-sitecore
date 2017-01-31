if(Get-Command -Name "Add-WindowsFeature")
{        
    Import-Module ServerManager
    Add-WindowsFeature Web-Server 
    Add-WindowsFeature NET-Framework-45-ASPNET 
    Add-WindowsFeature Web-Asp-Net45 
}else {
    throw "Could not add windows features"
}