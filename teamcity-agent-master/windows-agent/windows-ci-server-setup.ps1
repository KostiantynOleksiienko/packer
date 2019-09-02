$ErrorActionPreference = "Stop"

$PACKAGES_DIRECTORY = Join-Path $env:TEMP "packages"
$PACKAGES = @{
    "git" = @{
        "url" = "http://dcos-win.westus2.cloudapp.azure.com/downloads/git/Git-2.17.1.2-64-bit.exe"
        "local_file" = Join-Path $PACKAGES_DIRECTORY "git.exe"
    }
    "python36" = @{
        "url" = "https://www.python.org/ftp/python/3.6.5/python-3.6.5-amd64.exe"
        "local_file" = Join-Path $PACKAGES_DIRECTORY "python.exe"
    }
        "msys2" = @{
        "url" = "http://dcos-win.westus2.cloudapp.azure.com/downloads/msys2-x64.zip"
        "local_file" = Join-Path $PACKAGES_DIRECTORY "msys2.zip"
    }
    "7z" = @{
        "url" = "https://www.7-zip.org/a/7z1801-x64.exe"
        "local_file" = Join-Path $PACKAGES_DIRECTORY "7z.exe"
    }
}

filter Timestamp {
    "[$(Get-Date -Format o)] $_"
}

function Write-Log {
    Param(
        [string]$Message
    )
    $msg = $message | Timestamp
    Write-Output $msg
}

function Start-ExecuteWithRetry {
    Param(
        [Parameter(Mandatory=$true)]
        [ScriptBlock]$ScriptBlock,
        [int]$MaxRetryCount=10,
        [int]$RetryInterval=3,
        [string]$RetryMessage,
        [array]$ArgumentList=@()
    )
    $currentErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $retryCount = 0
    while ($true) {
        try {
            $res = Invoke-Command -ScriptBlock $ScriptBlock `
                                  -ArgumentList $ArgumentList
            $ErrorActionPreference = $currentErrorActionPreference
            return $res
        } catch [System.Exception] {
            $retryCount++
            if ($retryCount -gt $MaxRetryCount) {
                $ErrorActionPreference = $currentErrorActionPreference
                Throw
            } else {
                if($RetryMessage) {
                    Write-Log "Start-ExecuteWithRetry RetryMessage: $RetryMessage"
                } elseif($_) {
                    Write-Log "Start-ExecuteWithRetry Retry: $_.ToString()"
                }
                Start-Sleep $RetryInterval
            }
        }
    }
}

function Start-FileDownload {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$URL,
        [Parameter(Mandatory=$true)]
        [string]$Destination,
        [Parameter(Mandatory=$false)]
        [int]$RetryCount=10
    )
    $params = @('-fLsS', '-o', "`"${Destination}`"", "`"${URL}`"")
    Start-ExecuteWithRetry -ScriptBlock {
        $p = Start-Process -FilePath 'curl.exe' -NoNewWindow -ArgumentList $params -Wait -PassThru
        if($p.ExitCode -ne 0) {
            Throw "Fail to download $URL"
        }
    } -MaxRetryCount $RetryCount -RetryInterval 3 -RetryMessage "Failed to download ${URL}. Retrying"
}

function Start-LocalPackagesDownload {
    Write-Log "Downloading all the packages to local directory: $PACKAGES_DIRECTORY"
    if(!(Test-Path $PACKAGES_DIRECTORY)) {
        New-Item -ItemType "Directory" -Path $PACKAGES_DIRECTORY
    }
    foreach($pkg in $PACKAGES.Keys) {
        if(!$PACKAGES[$pkg]["url"]) {
            if(!(Test-Path $PACKAGES[$pkg]["local_file"])) {
                Throw "Package $pkg must be manually downloaded to: $($PACKAGES[$pkg]["local_file"])"
            }
            continue
        }
        Write-Log "Downloading: $($PACKAGES[$pkg]["url"])"
        Start-FileDownload -URL $PACKAGES[$pkg]["url"] -Destination $PACKAGES[$pkg]["local_file"]
    }
    Write-Log "Finished downloading all the packages"
}

function Add-ToSystemPath {
    Param(
        [Parameter(Mandatory=$false)]
        [string[]]$Path
    )
    if(!$Path) {
        return
    }
    $systemPath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine').Split(';')
    $currentPath = $env:PATH.Split(';')
    foreach($p in $Path) {
        if($p -notin $systemPath) {
            $systemPath += $p
        }
        if($p -notin $currentPath) {
            $currentPath += $p
        }
    }
    $env:PATH = $currentPath -join ';'
    setx.exe /M PATH ($systemPath -join ';')
    if($LASTEXITCODE) {
        Throw "Failed to set the new system path"
    }
}

function Install-CITool {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$InstallerPath,
        [Parameter(Mandatory=$false)]
        [string]$InstallDirectory,
        [Parameter(Mandatory=$false)]
        [string[]]$ArgumentList,
        [Parameter(Mandatory=$false)]
        [string[]]$EnvironmentPath
    )
    if($InstallDirectory -and (Test-Path $InstallDirectory)) {
        Write-Log "$InstallerPath is already installed."
        Add-ToSystemPath -Path $EnvironmentPath
        return
    }
    $parameters = @{
        'FilePath' = $InstallerPath
        'Wait' = $true
        'PassThru' = $true
    }
    if($ArgumentList) {
        $parameters['ArgumentList'] = $ArgumentList
    }
    if($InstallerPath.EndsWith('.msi')) {
        $parameters['FilePath'] = 'msiexec.exe'
        $parameters['ArgumentList'] = @("/i", $InstallerPath) + $ArgumentList
    }
    Write-Log "Installing $InstallerPath"
    $p = Start-Process @parameters
    if($p.ExitCode -ne 0) {
        Throw "Failed to install: $InstallerPath"
    }
    Add-ToSystemPath -Path $EnvironmentPath
    Write-Log "Successfully installed: $InstallerPath"
}

function Install-ZipCITool {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ZipPath,
        [Parameter(Mandatory=$true)]
        [string]$InstallDirectory,
        [Parameter(Mandatory=$false)]
        [string[]]$EnvironmentPath
    )
    if(Test-Path $InstallDirectory) {
        Write-Log "$ZipPath is already installed."
        Add-ToSystemPath -Path $EnvironmentPath
        return
    }
    New-Item -ItemType "Directory" -Path $InstallDirectory
    $extension = $ZipPath.Split('.')[-1]
    if($extension -ne "zip") {
        Throw "ERROR: $ZipPath is not a zip package"
    }
    7z.exe x $ZipPath -o"$InstallDirectory" -y
    if($LASTEXITCODE) {
        Throw "ERROR: Failed to extract $ZipPath to $InstallDirectory"
    }
    Add-ToSystemPath $EnvironmentPath
}

function Install-Docker {
    $service = Get-Service "Docker" -ErrorAction SilentlyContinue
    if($service) {
        Stop-Service "Docker"
        sc.exe delete "Docker"
        if($LASTEXITCODE) {
            Throw "ERROR: Failed to delete existing Docker service"
        }
    }
    $dockerRegKey = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\docker"
    if(Test-Path $dockerRegKey) {
        Remove-Item $dockerRegKey
    }
    $installDir = Join-Path $env:ProgramFiles "Docker"
    if(!(Test-Path $installDir)) {
        New-Item -ItemType "Directory" -Path $installDir
    }
    $dockerUrl = "http://dcos-win.westus2.cloudapp.azure.com/downloads/docker/18-03-1-ee-1/docker.exe"
    $dockerdUrl = "http://dcos-win.westus2.cloudapp.azure.com/downloads/docker/18-03-1-ee-1/dockerd.exe"
    Start-FileDownload -URL $dockerUrl -Destination "$installDir\docker.exe"
    Start-FileDownload -URL $dockerdUrl -Destination "$installDir\dockerd.exe"
    Add-ToSystemPath -Path $installDir
    dockerd.exe --register-service
    if($LASTEXITCODE) {
        Throw "ERROR: Failed to register Docker as a Windows service"
    }
    Start-Service "Docker"
}

function Install-Git {
    $installDir = Join-Path $env:ProgramFiles "Git"
    Install-CITool -InstallerPath $PACKAGES["git"]["local_file"] `
                   -InstallDirectory $installDir `
                   -ArgumentList @("/SILENT") `
                   -EnvironmentPath @("$installDir\cmd", "$installDir\bin")
    git.exe config --global core.autocrlf true
    if($LASTEXITCODE) {
        Throw "Failed to set git global config core.autocrlf true"
    }
    git.exe config --system core.symlinks true
    if($LASTEXITCODE) {
        Throw "Failed to set git system config core.symlinks true"
    }
}

function Install-Python36 {
    $installDir = Join-Path $env:ProgramFiles "Python36"
    Install-CITool -InstallerPath $PACKAGES["python36"]["local_file"] `
                   -InstallDirectory $installDir `
                   -ArgumentList @("/quiet", "InstallAllUsers=1", "TargetDir=`"$installDir`"") `
                   -EnvironmentPath @($installDir, "$installDir\Scripts")
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name LongPathsEnabled -Value 1
}

function Install-Msys2 {
    $installDir = Join-Path $env:ProgramFiles "msys2"
    try {
        Install-ZipCITool -ZipPath $PACKAGES["msys2"]["local_file"] `
                          -InstallDirectory $installDir `
                          -EnvironmentPath @("$installDir\usr\bin")
    } catch {
        Remove-Item -Recurse -Force $installDir
        Throw
    }
    pacman.exe -Syu make --noconfirm
    if($LASTEXITCODE) {
        Throw "ERROR: Failed to install make via msys2 pacman"
    }
}

function Install-7Zip {
    $installDir = Join-Path $env:ProgramFiles "7-Zip"
    Install-CITool -InstallerPath $PACKAGES["7z"]["local_file"] `
                   -InstallDirectory $installDir `
                   -ArgumentList @("/S") `
                   -EnvironmentPath @($installDir)
}

try {
    Write-Log "Started the CI server setup"
    Start-LocalPackagesDownload
    Set-MpPreference -DisableRealtimeMonitoring $true
    Install-Docker
    Install-Git
    Install-Python36
    Install-7Zip
    Install-Msys2
    Write-Log "Finished the CI server setup"
} catch {
    Write-Log "Failed the CI server setup"
    Write-Log $_.ToString()
    Write-Log $_.ScriptStackTrace
    exit 1
}
exit 0
