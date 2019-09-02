# Get json file which has to be passed as a parameter (-json <file>)
param ($json)

# Read JSON file
$data = (Get-Content $json -Raw)| ConvertFrom-Json

<#
    .DESCRIPTION
        Installs a package through chocolatey.
    
    .PARAMETER $name
        Package name
    .PARAMETER $version
        Package version
    .PARAMETER

    .EXAMPLE
        chocoInstall('ruby', '2.1.5')
    
    .NOTES
        This automatically adds the multiple version flag (-m).
#>
function chocoInstall ($name, $version) {
    Write-Host "Installing '$name', version '$version'"
    $chocoCmd = "C:\ProgramData\chocolatey\bin\choco install $name --version $version -my"
    iex $chocoCmd
}

# Loop over packages
foreach($package in $data.packages) {
    chocoInstall $package.name $package.version
}
