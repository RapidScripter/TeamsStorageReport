<#
.SYNOPSIS
Generates a CSV Report of Teams Storage including Private channels

.PARAMETER ClientID
Application (Client) ID of the App Registration

.PARAMETER ClientSecret
Client Secret from the App Registration

.PARAMETER TenantID
Directory (Tenant) ID of the Azure AD Tenant

.PARAMETER CSVPath
Path and name of the export CSV

.USAGE
.\TeamsStorageReport.ps1 -ClientSecret $clientSecret -ClientID $clientID -TenantID $tenantID -CSVPath $CSVPath

.EXAMPLE
.\TeamsStorageReport.ps1 -ClientSecret "-Uy8Q~vgvgfghfhgfvhgvkjgffdvfgvgh.c06" -ClientID "xxxxxxx-e193-41a3-b58e-xxxxxxxxxxxx" -TenantID "878yut128-2790-4a72-b398-73123hgtyi98998" -CSVPath "D:\Reports\TeamsReport.csv"

.Notes
Install Microsoft Teams and Graph PowerShell Module
Install-Module -Name MicrosoftTeams -Force -AllowClobber
Install-Module Microsoft.Graph -Scope CurrentUser
#>

param (
    [parameter(Mandatory = $true)]
    [string]$ClientSecret,

    [parameter(Mandatory = $true)]
    [string]$ClientID,

    [parameter(Mandatory = $true)]
    [string]$TenantID,

    [parameter(Mandatory = $true)]
    [string]$CSVPath
)

function GetGraphToken {
    <#
    .SYNOPSIS
    Azure AD OAuth Application Token for Graph API
    Get OAuth token for an AAD Application (returned as $token)
    #>

    param (
        [parameter(Mandatory = $true)]
        [string]$ClientId,

        [parameter(Mandatory = $true)]
        [string]$TenantId,

        [parameter(Mandatory = $true)]
        [string]$ClientSecret
    )

    try {
        $uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
        
        $body = @{
            client_id     = $clientId
            scope         = "https://graph.microsoft.com/.default"
            client_secret = $clientSecret
            grant_type    = "client_credentials"
        }

        $tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing

        if ($tokenRequest.StatusCode -ne 200) {
            throw "Failed to retrieve access token. Status code: $($tokenRequest.StatusCode)."
        }

        $token = ($tokenRequest.Content | ConvertFrom-Json).access_token
        return $token
    }
    catch {
        Write-Error "Error retrieving access token: $_"
        exit 1
    }
}

function RunGraphQuery {
    <#
    .SYNOPSIS
    Executes a Graph API query and handles pagination if necessary.
    Returns the results.
    #>

    param (
        [parameter(Mandatory = $true)]
        [string]$ApiUri,

        [parameter(Mandatory = $true)]
        [string]$Token
    )

    try {
        $results = Invoke-RestMethod -Headers @{Authorization = "Bearer $Token"} -Uri $ApiUri -Method Get
        
        # Check if there are more pages and retrieve them if so
        $resultsValue = $results.value
        $nextLink = $results.'@odata.nextLink'

        while ($nextLink) {
            Write-Host "Enumerating next page..." -ForegroundColor Yellow
            $nextPageRequest = Invoke-RestMethod -Headers @{Authorization = "Bearer $Token"} -Uri $nextLink -Method Get
            $resultsValue += $nextPageRequest.value
            $nextLink = $nextPageRequest.'@odata.nextLink'
        }

        return $resultsValue
    }
    catch {
        Write-Error "Error querying Graph API: $_"
        return $null
    }
}

# Validate parameters
if (-not $ClientSecret -or -not $ClientID -or -not $TenantID -or -not $CSVPath) {
    Write-Error "Missing required parameters. Please provide ClientSecret, ClientID, TenantID, and CSVPath."
    exit 1
}

# Generate access token
$token = GetGraphToken -ClientId $ClientID -ClientSecret $ClientSecret -TenantId $TenantID

# Define API URIs
$teamsApiUri = "https://graph.microsoft.com/beta/groups?`$filter=resourceProvisioningOptions/Any(x:x eq 'Team')"
$teamsCsvPath = $CSVPath

try {
    # Retrieve all Teams
    $teams = RunGraphQuery -ApiUri $teamsApiUri -Token $token

    foreach ($team in $teams) {
        # Retrieve Team drive details
        $teamDriveApiUri = "https://graph.microsoft.com/v1.0/groups/$($team.id)/drive"
        $teamDrive = Invoke-RestMethod -Headers @{Authorization = "Bearer $token"} -Uri $teamDriveApiUri -Method Get

        # Export Team storage details to CSV
        $teamExportObject = [PSCustomObject]@{
            "Team ID"              = $team.id
            "Team Name"            = $team.DisplayName
            "Channel Name"         = "N/A"
            "Channel Type"         = "N/A"
            "SharePoint URL"       = $teamDrive.webUrl
            "Storage Used (Bytes)" = $teamDrive.quota.used
        }
        $teamExportObject | Export-Csv -Path $teamsCsvPath -NoClobber -NoTypeInformation -Append

        # Retrieve Team channels
        $channelsApiUri = "https://graph.microsoft.com/v1.0/teams/$($team.id)/channels"
        $channels = RunGraphQuery -ApiUri $channelsApiUri -Token $token

        foreach ($channel in $channels) {
            # Handle private channel files folder query
            $channelFilesApiUri = "https://graph.microsoft.com/beta/teams/$($team.id)/channels/$($channel.id)/filesfolder"
            try {
                $channelDrive = Invoke-RestMethod -Headers @{Authorization = "Bearer $token"} -Uri $channelFilesApiUri -Method Get
            }
            catch {
                Write-Warning "Channel files not provisioned for $($channel.displayName)"
                continue
            }

            # Export Channel storage details to CSV
            $channelExportObject = [PSCustomObject]@{
                "Team ID"              = $team.id
                "Team Name"            = $team.DisplayName
                "Channel Name"         = $channel.displayName
                "Channel Type"         = $channel.membershipType
                "SharePoint URL"       = $channelDrive.webUrl
                "Storage Used (Bytes)" = $channelDrive.size
            }
            $channelExportObject | Export-Csv -Path $teamsCsvPath -NoClobber -NoTypeInformation -Append
        }
    }

    # Success message after successful completion
    Write-Host "Teams Storage Report generated successfully and saved at $CSVPath" -ForegroundColor Green
}
catch {
    Write-Error "Error in script execution: $_"
    exit 1
}
