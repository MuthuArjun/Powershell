$vmhosts = get-vmhost | sort Name

foreach ($vmhost in $vmhosts)
    {
        Write-Host "`nChecking $vmhost for UCS fnic version...`n"
        $esxcli = get-esxcli -VMHost $vmhost
        $fnic = $esxcli.software.vib.list() | where {$_.Name -eq "scsi-fnic"}
        Write-Host "The fnic version for $vmhost is:`n"
        $fnic
        Write-Host "`n`n"

    }