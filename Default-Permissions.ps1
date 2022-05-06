<# 
.SYNOPSIS
    PowerShell Script to define the permissions required by Azure AD Connect

.DESCRIPTION
    The script will define the required permissions for Azure AD Connect depending of your environment.

.EXAMPLE
    Read permissions and mS-DS-ConsistencyGuid permissions
    PS C:\> Default-Permissions.ps1 -GroupName "myGroup" -Basic

.EXAMPLE
    Password Hash Sync permissions
    PS C:\> Default-Permissions.ps1 -GroupName "myGroup" -PHS

.EXAMPLE
    Password Writeback permissions
    PS C:\> Default-Permissions.ps1 -GroupName "myGroup" -PasswordWriteback

.NOTES
    

.LINK
    https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-configure-ad-ds-connector-account

#>
Param(
    [Switch]$Basic,
    [Switch]$PHS,
    [Switch]$ExchangeHybrid,
    [Switch]$PublicFolder,
    [Switch]$PasswordWriteback,
    [Switch]$UnifiedGroupWriteback,
    [Parameter(Mandatory=$true, Position=0)]
    $GroupName
)
[boolean]$Continue = $false
## Check module
If (!(Get-Module -Name ADSyncConfig)){
    Write-Host "Module ADSyncConfig is not present" -ForegroundColor Red
} Else {
    Write-Host "Module launched" -ForegroundColor Yellow
    Import-Module "C:\Program Files\Microsoft Azure Active Directory Connect\AdSyncConfig\ADSyncConfig.psm1"
}

## Get AD Connector
$ADConnector = (Get-ADSyncADConnectorAccount).ADConnectorName

Try {
    $DomainDN = (Get-ADDomain $ADConnector).DistinguishedName
}
Catch {
    Write-Host "Domain not found or something went wrong" -ForegroundColor Red
}
Finally {
    [boolean]$Continue = $true
}

Try {
    $Object = Get-ADGroup -Identity $GroupName
}
Catch {
    Write-Host "Group not found or something went wrong" -ForegroundColor Red
}
Finally {
    [boolean]$Continue = $true
}

## Get AD Connector
$ADConnector = (Get-ADSyncADConnectorAccount).ADConnectorName

## -IncludeAdminSDHolders: will not used because not High Privilege account should be synced
IF ($Continue = $true) {
    Write-Host "Set permissions" -ForegroundColor Yellow
    $Parameter = $MyInvocation.BoundParameters.Keys
    Switch ($Parameter) {
        "Basic"{
            Write-Host "  Basic permissions" -ForegroundColor Green
            ## Read Property access on all attributes for all descendant objects
            Set-ADSyncBasicReadPermissions -ADConnectorAccountName $GroupName -ADConnectorAccountDomain $ADConnector -ADobjectDN $DomainDN | Out-Null
            Write-Host "  MsDsConsistencyGuid permissions" -ForegroundColor Green
            ## Read/Write Property access on mS-DS-ConsistencyGuid attribute for all descendant objects
            Set-ADSyncMsDsConsistencyGuidPermissions -ADConnectorAccountName $GroupName -ADConnectorAccountDomain $ADConnector -ADobjectDN $DomainDN | Out-Null
        }
        "PHS"{
            Write-Host "  Password Hash Sync permissions" -ForegroundColor Green
            ## Replicating Directory Changes/Replicating Directory Changes All
            Set-ADSyncPasswordHashSyncPermissions -ADConnectorAccountName $GroupName -ADConnectorAccountDomain $ADConnector | Out-Null
        }
        "ExchangeHybrid"{
            Write-Host "  Exchange Hybrid permissions" -ForegroundColor Green
            ## Read/Write Property access on all attributes for all descendant objects
            Set-ADSyncExchangeHybridPermissions -ADConnectorAccountName $GroupName -ADConnectorAccountDomain $ADConnector -ADobjectDN $DomainDN | Out-Null
        }
        "PublicFolder"{
            Write-Host "  Public Folder permissions" -ForegroundColor Green
            ## Read Property access on all attributes for all descendant objects
            Set-ADSyncExchangeMailPublicFolderPermissions -ADConnectorAccountName $GroupName -ADConnectorAccountDomain $ADConnector -ADobjectDN $DomainDN | Out-Null
        }
        "PasswordWriteback"{
            Write-Host "  password Writeback permissions" -ForegroundColor Green
            ## Reset Password on descendant objects/Write Property access on lockoutTime attribute for all descendant objects/Write Property access on pwdLastSet attribute for all descendant objects
            Set-ADSyncPasswordWritebackPermissions -ADConnectorAccountName $GroupName -ADConnectorAccountDomain $ADConnector -ADobjectDN $DomainDN | Out-Null
        }
        "UnifiedGroupWriteback"{
            Write-Host "  Unified Group Writeback permissions" -ForegroundColor Green
            ## Generic Read/Write, Delete, Delete Tree and Create/Delete Child for all group Object types and SubObjects
            Set-ADSyncUnifiedGroupWritebackPermissions -ADConnectorAccountName $GroupName -ADConnectorAccountDomain $ADConnector -ADobjectDN $DomainDN | Out-Null
        }
    }

    ### Security
    ## No necessary if you implemented T0 and your account is under T0 OU
    # Set-ADSyncRestrictedPermissions [-ADConnectorAccountDN] <String> [-Credential] <PSCredential> [-DisableCredentialValidation] [-WhatIf] [-Confirm] [<CommonParameters>]
}Else{
    Write-Host "Something went wrong" -ForegroundColor Red
}