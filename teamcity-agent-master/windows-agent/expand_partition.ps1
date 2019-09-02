Write-Output "Expanding root partition"
$maxSize = (Get-PartitionSupportedSize -DriveLetter c).sizeMax
Resize-Partition -DriveLetter c -Size $maxSize
