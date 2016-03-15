<#

This script checks each host in all clusters for the vCPU subscription
rate, displays it, and also exports it to a csv.

Created by Jesse Evenson 12-2-14
#>

# Static variables

$vcenter = "vcenterhq"
$outfile = "C:\Users\jevenson\Desktop\CPU_Subscription.csv"



#check if the PowerCLI snapin is installed and loaded

if(!(Get-PSSnapin -Registered -Name VMware.VimAutomation.Core))
    {
        Write-Host "You must run this script on a computer with PowerCLI installed."
        exit;
    }

if (!(Get-PSSnapin -Name VMware.VimAutomation.Core -ea silentlycontinue))
    {
        Write-Host "`nAdding the PowerCLI Snapin...`n"
        Add-PsSnapin VMware.VimAutomation.Core -ea SilentlyContinue
    }

#check to see if you are connected to vCenter and connect if it's not.
if(!($global:DefaultVIServers.Count -gt 0))
    {
        Write-Host "`nConnecting to $vcenter...`n"
        connect-viserver $vcenter
    }



$vmCpuSubscription = @()
$clusters = get-cluster

foreach ($cluster in $clusters)
    {
        Write-Host "`nChecking $cluster CPU subscription...`n"
        $vmhosts = Get-cluster $cluster | get-vmhost
        
        foreach ($vmhost in $vmhosts)
            {
                $vmobj = "" | Select Cluster, VMHost, HostCPU, "vCPU Allocated", "CPU Subscription(HT)", "CPU Subscription(no HT)"
                $vmobj.Cluster = $cluster
                $vmobj.VMHost = $vmhost.name
                $vms=$vmhost|get-vm
                $vmsVcpucount=($vms|Measure-Object -Property numcpu -Sum).sum
                ""|Select @{N='Host';E={$vmhost.name}},@{N='CPU Count';E={$vmhost.numcpu}},@{N='Actual vCPU allocated';E={$vmsVcpucount}},@{N='CPU Subscription(HT)';E={"{0:N1}" -f ($vmsVcpucount/($vmhost.numcpu*2))+":1"}},@{N='CPU Subscription(no HT)';E={"{0:N1}" -f ($vmsVcpucount/$vmhost.numcpu)+":1"}}  
                $vmobj.HostCPU=$vmhost.numcpu 
                $vmobj.'vCPU Allocated'=$vmsVcpucount
                $vmobj.'CPU Subscription(HT)'="{0:N1}" -f ($vmsVcpucount/($vmhost.numcpu*2))
                $vmobj.'CPU Subscription(no HT)'="{0:N1}" -f ($vmsVcpucount/$vmhost.numcpu)
                $vmCpuSubscription += $vmobj
            }
    }
$vmCpuSubscription | ft -AutoSize
$vmCpuSubscription | Export-Csv $outfile -NoTypeInformation