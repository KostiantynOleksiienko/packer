Import-Module $PSScriptRoot\helpers.psm1


<#
    .DESCRIPTION
        Install the bsdtar tools

    .EXAMPLE
        Install-bsdtar
#>
function Install-bsdtar {
    Write-Output "Installing bsdtar"
    $bsdtarInstaller = Join-Path $env:TEMP "libarchive-setup.exe"
    Start-FileDownload -URL "http://downloads.sourceforge.net/gnuwin32/libarchive-2.4.12-1-setup.exe" -Destination $bsdtarInstaller
    $p = Start-Process -Wait -PassThru -FilePath $bsdtarInstaller -ArgumentList @("/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART")
    if($p.ExitCode -ne 0) { Throw "Failed to install bsdtar" }
    Remove-Item $bsdtarInstaller

    Add-ToSystemPath -Path "C:\\Program Files (x86)\\GnuWin32\\bin"

    if($LASTEXITCODE) {
        Throw "Failed to install bsdtar"
    }
}


try {
    Install-bsdtar
} catch {
    Write-Output $_.ToString()
    Write-Output $_.ScriptStackTrace
    exit 1
}
exit 0
