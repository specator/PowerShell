$vmname = 'server-sp-1'
$vmdomain = 'portalvp.ru'
$vmbasepath = 'G:\Hyper-V\'
#-ProcessorCount
#-DynamicMemory
#-StaticMemory
#-MemoryMinimumBytes 512MB
#-MemoryMaximumBytes 4GB
#-MemoryStartupBytes 1GB


$vmfullname = $vmname + '.' + $vmdomain
$vmvhdpath = $vmbasepath + $vmfullname + '\Virtual Hard Disks\' + $vmfullname + '.vhdx'
$vmvfdpath = $vmbasepath + $vmfullname + '\Virtual Hard Disks\' + $vmfullname + '.vfd'

New-Item -ItemType File -Path $vmvhdpath -Force
Copy-Item -Path G:\Hyper-V\server.portalvp.ru.vhdx -Destination $vmvhdpath -Force

#Resize-VHD -Path $vmvhdpath -SizeBytes 50GB

New-VM -Name $vmfullname -MemoryStartupBytes 1GB -Path $vmbasepath -VHDPath $vmvhdpath -SwitchName "HOME Network"

Set-VM -Name $vmfullname -AutomaticStartAction StartIfRunning -AutomaticStopAction ShutDown -ProcessorCount 4 -DynamicMemory -MemoryMinimumBytes 512MB -MemoryMaximumBytes 4GB -MemoryStartupBytes 2GB

Start-VM -Name $vmfullname
