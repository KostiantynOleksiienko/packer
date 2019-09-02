Import-Module $PSScriptRoot\helpers.psm1


<#
    .DESCRIPTION
        Upgrade the Docker service

    .EXAMPLE
        Upgrade-Docker
#>
function Upgrade-Docker {
    Write-Output "Upgrading Docker service"
    $dockerInstaller = Join-Path $env:TEMP "docker.zip"
    Start-FileDownload -URL "https://download.docker.com/win/static/edge/x86_64/docker-17.10.0-ce.zip" -Destination $dockerInstaller
    Stop-Service "Docker"
    Expand-Archive -Force $dockerInstaller -DestinationPath $Env:ProgramFiles
    Start-Service "Docker"
    Remove-Item $dockerInstaller

    if($LASTEXITCODE) {
        Throw "Failed to upgrade Docker service"
    }
}


try {
    Upgrade-Docker
} catch {
    Write-Output $_.ToString()
    Write-Output $_.ScriptStackTrace
    exit 1
}
exit 0
