Import-Module $PSScriptRoot\helpers.psm1


<#
    .DESCRIPTION
        Install the TeamCity agent service

    .EXAMPLE
        Install-TeamCity-agent
#>
function Install-TeamCity-agent {
    Write-Output "Installing TeamCity agent"
    $tcAgentInstaller = Join-Path $env:TEMP "agentInstaller.exe"
    Start-FileDownload -URL "https://teamcity.mesosphere.io/update/agentInstaller.exe" -Destination $tcAgentInstaller
    $p = Start-Process -Wait -PassThru -FilePath $tcAgentInstaller -ArgumentList @("/S", "/install", "/passive", "/qn")
    if($p.ExitCode -ne 0) { Throw "Failed to install TeamCity agent" }
    Remove-Item $tcAgentInstaller

    C:\BuildAgent\launcher\bin\TeamCityAgentService-windows-x86-32.exe -i C:\BuildAgent\launcher\conf\wrapper.conf

    if($LASTEXITCODE) {
        Throw "Failed to install TeamCity agent service"
    }
}


try {
    Install-TeamCity-agent
} catch {
    Write-Output $_.ToString()
    Write-Output $_.ScriptStackTrace
    exit 1
}
exit 0
