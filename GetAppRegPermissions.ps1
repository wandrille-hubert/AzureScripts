### If no argument provided, will print out list of permissions in the shell: .\GetAppRegPermissions.ps1
### If want to export to csv, provide output filepath as argument: .\GetAppRegPermissions.ps1 C:\Temp\appperms.csv


## If not installed, will need to install AzureAD module (https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-adv2?view=azureadps-2.0#installing-the-azure-ad-module)
# Install-Module AzureAD

## Need to connect to AzureAD before being able to run the script, TenantId can be specified
# Connect-AzureAD
# Connect-AzureAD -TenantId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx



$output = foreach ($app in Get-AzureADApplication -All $true) {
    foreach ($resource in $app.RequiredResourceAccess) {

        $resourceEntity = Get-AzureADServicePrincipal -Filter ("appId eq '$($resource.ResourceAppId)'")

        foreach ($access in $resource.ResourceAccess) {

            $apppermission = New-Object PSObject -Property ([ordered]@{
                'AppName' = $app.DisplayName
                'AppId' = $app.AppId
                'ResourceObjectId' = $resourceEntity.ObjectId
                'ResourceAppId' = $resource.ResourceAppId
                'ResourceName' = $resourceEntity.DisplayName
                'Type' = ''
                'Permission' = ''
            })
            if ($access.Type -eq 'Role') {
                $role = $resourceEntity.AppRoles | Where-Object { $_.Id -eq $access.Id }
                $apppermission.Type = 'Application'
                $apppermission.Permission = $role.Value
            }
            elseif ($access.Type -eq 'Scope') {
                $role = $resourceEntity.OAuth2Permissions | Where-Object { $_.Id -eq $access.Id }
                $apppermission.Type = 'Delegated'
                $apppermission.Permission = $role.Value
            }

            $apppermission
        }
    }
}

$outputfile = $args[0]
if ($outputfile) { 
    $output | Export-Csv -Path $outputfile
}
else {
    echo $output
}