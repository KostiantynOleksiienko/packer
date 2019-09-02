<#
    .DESCRIPTION
        Adds a path into the windows PATH environment var
    .PARAMETER $Path
        The path location (folder) to add

    .EXAMPLE
        Add-ToSystemPath -Path "C:\\Program Files\\App\\bin"
#>
function Add-ToSystemPath {
    Param(
        [Parameter(Mandatory=$true)]
        [string[]]$Path
    )
    Write-Output "Adding $Path to system PATH environment"
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$Path", [EnvironmentVariableTarget]::Machine)

    if($LASTEXITCODE) {
        Throw "Failed to set the new system path"
    }
}
Export-ModuleMember -Function 'Add-ToSystemPath'


<#
    .DESCRIPTION
        Start a file download via System.Net.WebClient

    .PARAMETER $URL
        URL of the file to download
    .PARAMETER $Destination
        On-disk destination of the downloaded file
    .PARAMETER $Force
        Force download (ignore certificate errors)

    .EXAMPLE
        Start-FileDownload -URL "https://example.com/file.exe" -Destination "C:\file.exe"
#>
function Start-FileDownload {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$URL,
        [Parameter(Mandatory=$true)]
        [string]$Destination,
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )
    if($Force) {
        [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    }
    Write-Output "Downloading $URL to $Destination"
    $webclient = New-Object System.Net.WebClient
    $webclient.DownloadFile($URL, $Destination)
}
Export-ModuleMember -Function 'Start-FileDownload'
