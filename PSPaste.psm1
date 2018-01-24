$Script:URL = "https://p.lee.io"

function Get-Paste
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string[]]$UUID
    )

    Begin
    {
        $Results = @()
    }

    Process
    {
        foreach ($CurrentUUID in $UUID)
        {
            try
            {
                $ResponseData = Invoke-Request -Resource "/v1/paste/$CurrentUUID" -Method Get
            }
            catch
            {
                throw "Failed to retrieve paste; UUID=[$CurrentUUID] InnerException=[$($_.Exception.Message)]"
            }
            $Results += New-Object -TypeName PSObject -Property `
            @{
                UUID = $CurrentUUID
                Content = $ResponseData.content
                Syntax = (Get-Syntax | ? {$_.Syntax -eq $ResponseData.syntax})
                Expires = (Get-Expires | ? {$_.expires -eq $ResponseData.expires})
            }
        }
    }

    End
    {
        return $Results
    }
}

function New-Paste
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string[]]$Content,
        [Parameter(Mandatory=$false)][string]$Syntax,
        [Parameter(Mandatory=$false)][string]$Expires
    )

    Begin
    {
        $Results = @()
    }

    Process
    {
        foreach ($CurrentContent in $Content)
        {
            $Body = New-Object -TypeName PSObject -Property `
            @{
                content = $CurrentContent
                syntax = $Syntax
                expires = $Expires
            }
    
            try
            {
                $ResponseData = Invoke-Request -Resource "/v1/paste" -Method Post -Body $Body
            }
            catch
            {
                throw "Failed to create paste; InnerException=[$($_.Exception.Message)]"
            }

            $Results += New-Object -TypeName PSObject -Property `
            @{
                UUID = $ResponseData.uuid
                URL = "$URL/$($ResponseData.uuid)"
            }
        }
    }

    End
    {
        return $Results
    }
}

function Get-Syntax
{
    try
    {
        $ResponseData = Invoke-Request -Resource "/v1/syntax" -Method Get
    }
    catch
    {
        throw "Failed to retrieve syntax; InnerException=[$($_.Exception.Message)]"
    }

    $Result = @()
    foreach ($Syntax in $ResponseData)
    {
        $Result += New-Object -TypeName PSObject -Property `
        @{
            Label = $Syntax.label
            Syntax = $Syntax.syntax
            Default = $Syntax.default
        }
    }

    return $Result
}

function Get-Expires
{
    try
    {
        $ResponseData = Invoke-Request -Resource "/v1/expires" -Method Get
    }
    catch
    {
        throw "Failed to retrieve expires; InnerException=[$($_.Exception.Message)]"
    }

    $Result = @()
    foreach ($Syntax in $ResponseData)
    {
        $Result += New-Object -TypeName PSObject -Property `
        @{
            Label = $Syntax.label
            Expires = $Syntax.expires
            Default = $Syntax.default
        }
    }

    return $Result
}

function Invoke-Request
{
    Param
    (
        [Parameter(Mandatory=$true)][string]$Resource,
        [Parameter(Mandatory=$true)][Microsoft.PowerShell.Commands.WebRequestMethod]$Method,
        [Parameter(Mandatory=$false)][object]$Body
    )

    $Result = Invoke-WebRequest -Uri "$URL/api/$($Resource.Trim('/'))" -Method $Method -Body ($Body | ConvertTo-Json) -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json
    if ($Result.success -ne $true)
    {
        throw $Result.data
    }

    return $Result.data
}

Export-ModuleMember -Function "Get-Paste","New-Paste","Get-Syntax","Get-Expires"
