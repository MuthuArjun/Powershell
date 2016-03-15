###############################################
#
# This script will set the PSP for each device
# on a given ESX host. It also changes the default
# PSP for new ALUA LUNs.
#
###############################################

param($vmhost)

if (!($vmhost))
    {
        Write-Host "`nYou must specify a host name. `n`nGet-Esx_device.ps1 -vmhost hostname `n`n"
        exit
    }

######################################
#
# Set default PSP
#
######################################

$satp = "VMW_SATP_ALUA"
$defaultpsp = "VMW_PSP_RR"
Write-Host "`nSetting the default Path Selection Policy for ALUA storage types on $vmhost to Round Robin."
$esxcli = Get-EsxCli -VMHost $vmhost
$esxcli.storage.nmp.satp.set($null,$defaultpsp,$satp)



$clarion = "These are the Clarion Datastores:`n=============================================================="
$vmax = "These are the VMAX Datastores:`n=============================================================="
$pure = "These are the Pure Storage Datastores:`n=============================================================="
$unknown = "These are the Unknown Datastores:`n=============================================================="


######################################
#
# Get's an array of the datastores and LUNs
#
######################################

$datastores = Get-VMHost -Name $vmhost | Get-Datastore | sort Name
$disks = Get-VMHost $vmhost | Get-ScsiLun -LunType disk

$entry = @()
$host_datastores = @()

ForEach ($disk in $disks){
  $entry = "" | Select DataStorename, Canonicalname, Multipathing, CorrectPSP
  $entry.datastorename = $datastores | Where-Object {($_.extensiondata.info.vmfs.extent | %{$_.diskname}) -contains $disk.canonicalname}|select -expand name
  #$entry.HostName = $disk.VMHost.Name$vmho
  $entry.canonicalname=$disk.canonicalname
  $entry.multipathing=$disk.multipathpolicy
  $host_datastores += $entry
}
$host_datastores = $host_datastores | where {$_.DataStorename -ne $null} | sort DataStorename
#$host_datastores

$ds_entry = @()
$ds_table = @()


######################################
#
# Checks each datastore to make sure it's
# PSP is set correctly.
#
######################################

foreach ($ds in $host_datastores)
    {
        $ds_entry = "" | Select DataStorename, Canonicalname, Multipathing, CorrectPSP
        $ds_entry.Datastorename = $ds.Datastorename
        $ds_entry.Canonicalname = $ds.Canonicalname
        $ds_entry.Multipathing = $ds.Multipathing
        
        if ($ds.DataStorename -like "EMC*")
            {
                $clarion += "`n$($ds.DataStorename) is a Clarion datastore with a CN of $($ds.Canonicalname) and should be set to MRU."
                
                if ($ds.multipathing -ne "MostRecentlyUsed")
                    {
                        Write-Host "`nThe multipathing policy on $($ds.Datastorename) is incorrect and needs to be changed."
                        $ds_entry.CorrectPSP = "No"
                        Get-VMHost -Name $vmhost | Get-ScsiLun -CanonicalName $ds.Canonicalname | Set-ScsiLun -MultipathPolicy "MostRecentlyUsed"
                    }
                elseif ($ds.multipathing -eq "MostRecentlyUsed")
                    {
                        Write-Host "The multipathing policy on $($ds.DataStorename) is already set correctly."
                        $ds_entry.CorrectPSP = "Yes"
                    }


            }
        elseif ($ds.DataStorename -like "HQ_*")
            {
                $vmax += "`n$($ds.DataStorename) is a VMAX datastore and should be set to RoundRobin."

                if ($ds.multipathing -ne "RoundRobin")
                    {
                        Write-Host "`nThe multipathing policy on $($ds.Datastorename) is incorrect and needs to be changed."
                        $ds_entry.CorrectPSP = "No"
                        Get-VMHost -Name $vmhost | Get-ScsiLun -CanonicalName $ds.Canonicalname | Set-ScsiLun -MultipathPolicy "RoundRobin"
                    }
                elseif ($ds.multipathing -eq "RoundRobin")
                    {
                        Write-Host "The multipathing policy on $($ds.DataStorename) is already set correctly."
                        $ds_entry.CorrectPSP = "Yes"
                    }
                
            }
        elseif ($ds.DataStorename -like "*pure*")
            {
                $pure += "`n$($ds.DataStorename) is a Pure Storage datastore and should be set to Round Robin."

                if ($ds.multipathing -ne "RoundRobin")
                    {
                        Write-Host "`nThe multipathing policy on $($ds.Datastorename) is incorrect and needs to be changed."
                        $ds_entry.CorrectPSP = "No"
                        Get-VMHost -Name $vmhost | Get-ScsiLun -CanonicalName $ds.Canonicalname | Set-ScsiLun -MultipathPolicy "RoundRobin"
                    }
                elseif ($ds.multipathing -eq "RoundRobin")
                    {
                        Write-Host "The multipathing policy on $($ds.DataStorename) is already set correctly."
                        $ds_entry.CorrectPSP = "Yes"
                    }
            }
        else
            {
                $unknown += "`n$($ds.DataStorename) didn't match any datastore pattern."
                $ds_entry.CorrectPSP = "Unknown"
            }  
            
     $ds_table += $ds_entry             

    }

#Write-Host $clarion`n`n
#Write-Host $clarion_device`n`n
#Write-Host $vmax`n`n
#Write-Host $pure`n`n
#Write-Host $unknown`n`n


######################################
#
# Displays the previous, and new settings
# and logs to a file called esx_multipathing.log
#
######################################

$previous =  "`n`n========================================================================`nThese are the previous PSP settings for $vmhost`n========================================================================"
$previous | Out-File -Append esx_multipathing.log
$ds_table | ft
$ds_table | ft -AutoSize | Out-File -Append esx_multipathing.log

$new = "`n`n========================================================================`nHere are the new Path Selection Policy settings for $vmhost`n========================================================================"
$new | Out-File -Append esx_multipathing.log

$disks = Get-VMHost $vmhost | Get-ScsiLun -LunType disk

$entry = @()
$host_datastores = @()

ForEach ($disk in $disks){
  $entry = "" | Select DataStorename, Canonicalname, Multipathing
  $entry.datastorename = $datastores | Where-Object {($_.extensiondata.info.vmfs.extent | %{$_.diskname}) -contains $disk.canonicalname}|select -expand name
  #$entry.HostName = $disk.VMHost.Name$vmho
  $entry.canonicalname=$disk.canonicalname
  $entry.multipathing=$disk.multipathpolicy
  $host_datastores += $entry
}
$host_datastores = $host_datastores | where {$_.DataStorename -ne $null} | sort DataStorename
$host_datastores | ft
$host_datastores | ft | Out-File -Append esx_multipathing.log