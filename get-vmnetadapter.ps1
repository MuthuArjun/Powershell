$vms = Get-vm | sort Name
$old_net = @()
$new_net = @()

foreach ($vm in $vms)
    {
        $vmobj = "" | select VMHost, NetAdapter
        $vmobj.vmhost = "$vm"

        $type = (get-vm $vm | Get-NetworkAdapter).type
        $vmobj.NetAdapter = $type
        
        if ($type -eq "Vmxnet3")
            {
                Write-Host "$vm is using a Vmxnet3 adapter."
                $new_net += $vmobj
            }
        else
            {
                Write-Host "$vm is using a " -NoNewline
                Write-Host "$type" -BackgroundColor Black -ForegroundColor Red -NoNewline
                Write-Host " adapter and should be changed."
                $old_net += $vmobj
                 
            }
    }

Write-Host "The following VM's need their adapters upgraded..."
$old_net
$old_net | Export-Csv C:\users\jevenson\Desktop\vms_with_old_net.csv

$new_net | Export-Csv C:\users\jevenson\Desktop\vms_with_new_net.csv