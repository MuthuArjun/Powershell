
Write-Host "Checking vm's for orphaned snapshots. This will take several minutes..."
$vms = Get-VM | ?{((get-harddisk $_).count*2)*((get-snapshot -vm $_).count + 1) -lt ($_.extensiondata.layoutex.file|?{$_.name -like "*vmdk"}).count}

$vms.extensiondata|%{$_.consolidatevmdisks_task()}

Write-Host "The following vm's had orphaned snapshots and were consolidated: "
Write-Host $vms
