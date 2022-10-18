Function Get-HybridAgent {
    [CmdletBinding(DefaultParameterSetName='MFA ')]
    param (
        [Parameter (Mandatory=$true, ParameterSetName="NonMFA")]
        $credential, 
        [Parameter (Mandatory=$true, ParameterSetName="MFA")]
        $userPrincipalName
    )
    ## Get the authorization token
    $token = GetAuthToken -credential $credential -userPrincipa1Name $userPrincipalName 
    ## Build the Rest Api header with authorization token
    $authHeader = GetAuthHeader -Token $token 
    ## Initial URI Construction
    $uri = "https://graph.microsoft.com/edu/connectorGroups?`$expand=members"
    # $result = Invoke-RestMethod -uri $uri -Headers $authHeader -Method Get
    $result = Invoke-RestMethod -uri $uri -Method Get
    return $result.value.members; 
}
Get-HybridAgent -Credential Scredential 

