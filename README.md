# TeamsStorageReport - Teams Storage Report Generator

## Overview
This PowerShell script generates a CSV report of Microsoft Teams storage usage, including details from private channels.

## Prerequisites
Before running the script, ensure you have the following installed:
- Microsoft Teams PowerShell module
   ```powershell
   Install-Module -Name MicrosoftTeams -Force -AllowClobber
- Microsoft Graph PowerShell module
   ```powershell
   Install-Module Microsoft.Graph -Scope CurrentUser

## Usage
1. Clone the repository or download the script.
   ```bash
   git clone https://github.com/RapidScripter/TeamsStorageReport
2. Open PowerShell.
3. Navigate to the directory where the script is located.
4. Run the script using the following parameters:
   ```powershell
   .\TeamsStorageReport.ps1 -ClientSecret "<ClientSecret>" -ClientID "<ClientID>" -TenantID "<TenantID>" -CSVPath "<path>\<FileName.csv>"
5. Example:
   ```powershell
   .\TeamsStorageReport.ps1 -ClientSecret "-Uy8Q~vgvgfghfhgfvhgvkjgffdvfgvgh.c06" -ClientID "xxxxxxx-e193-41a3-b58e-xxxxxxxxxxxx" -TenantID "878yut128-2790-4a72-b398-73123hgtyi98998" -CSVPath "D:\Reports\TeamsReport.csv"

## Parameters
- **ClientSecret**: Client Secret from the Azure AD App Registration.
- **ClientID**: Application (Client) ID of the Azure AD App Registration.
- **TenantID**: Directory (Tenant) ID of the Azure AD Tenant.
- **CSVPath**: Path and name of the export CSV file.

## Notes
- Ensure you have the necessary permissions in Azure AD and Microsoft Teams to retrieve storage information.
- The script uses Azure AD OAuth client credentials flow for authentication.
- For Application registration, refer to the provided PDF guide.
