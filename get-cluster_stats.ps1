param($cluster)
$clustername =Get-cluster $cluster
$Clusters = Get-View -ViewType ComputeResource | ? Name -like $clustername.name
$Clusters | % {
$Cluste     = $_
$VMHostsView = $null
$VMHostsView = Get-View $Cluste.Host -Property Name, Hardware, Config
$VMss         = $clustername | Get-VM
$HostCount        = ($VMHostsView | Measure-Object).Count
$VMCount          = 0 + ($VMss | Measure-Object).Count
$VMsPerHost       = [math]::round(($VMCount/$HostCount), 1)
$vCPU             = 0 + ($VMss | measure-object -sum -property NumCPU).Sum
$allocatedram      = 0 + ($VMss | measure-object -sum -property memorygb).Sum
$avgrampervm      = [math]::round(($allocatedram/$VMCount), 1)
$pCPUSocket       = ($VMHostsView | % { $_.Hardware.CPUInfo.NumCpuPackages } | Measure-Object -sum).Sum
$TpCPUSocket     += $pCPUSocket
$pCPUCore         = ($VMHostsView | % { $_.Hardware.CPUInfo.NumCpuCores } | Measure-Object -sum).Sum
$vCPUPerpCPUCore  = [math]::round(($vCPU/$pCPUCore), 1)
$onenode =[math]::round((Get-Cluster $cluster | Get-VMHost | Select -first 1 | measure-object -property memorytotalGB -sum).sum)
$twonode =[math]::round((Get-Cluster $cluster | Get-VMHost | Select -first 2 | measure-object -property memorytotalGB -sum).sum)
$onenodepcpucores =[math]::round((Get-Cluster $cluster | Get-VMHost | Select -first 1 | measure-object -property numcpu -sum).sum)
$twonodepcpucores =[math]::round((Get-Cluster $cluster | Get-VMHost | Select -first 2 | measure-object -property numcpu -sum).sum)
$totalclusterpcores_failover1= $pcpucore-$onenodepcpucores
$totalclusterpcores_failover2= $pcpucore-$twonodepcpucores
$TotalClusterRAMGB =[math]::round((Get-cluster $cluster | get-vmhost | % { $_ } | measure-object -property memorytotalGB -sum).sum)
$TotalClusterRAMFailoverOne = [math]::round(($TotalClusterRAMGB-$onenode))
$TotalClusterRAMFailvoerTwo = [math]::round(($TotalClusterRAMGB-$twonode))
$TotalClusterRAMusageGB =[math]::round((Get-cluster $cluster | get-vmhost | % { $_ } | measure-object -property memoryusageGB -sum).sum)
$TotalClusterRAMUsagePercent = [math]::round(($TotalClusterRAMusageGB/$TotalClusterRAMGB)*100)
$TotalClusterRAMFreeGB = [math]::round(($TotalClusterRAMGB-$TotalClusterRAMUsageGB))
$TotalClusterRAMReservedGB = [math]::round(($TotalClusterRAMGB/100)*15)
$TotalClusterRAMAvailable = [math]::round(($TotalClusterRAMFreeGB-$TotalClusterRAMReservedGB))
$TotalClusterRAMAvailable_FailoverOne = [math]::round(($TotalClusterRAMAvailable-$onenode))
$TotalClusterRAMAvailable_failoverTwo = [math]::round(($TotalClusterRAMAvailable-$twonode))
$TotalClustervcpuperpcore_FailoverOne = [math]::round(($vCPU/$totalclusterpcores_failover1))
$TotalClustervcpuperpcore_failoverTwo = [math]::round(($vCPU/$totalclusterpcores_failover2))
$newvmcount = [math]::round(($TotalClusterRAMAvailable/$avgrampervm))
$newvmcount_failover1 = [math]::round(($TotalClusterRAMAvailable_failoverone/$avgrampervm))
$newvmcount_failover2 = [math]::round(($TotalClusterRAMAvailable_failovertwo/$avgrampervm))
 
New-Object PSObject |
Add-Member -pass NoteProperty "ClusterName"          $clustername.name    |
Add-Member -pass NoteProperty "TotalClusterHostCount"          $HostCount    |
Add-Member -pass NoteProperty "TotalClusterVMCount"          $VMCount    |
Add-Member -pass NoteProperty "TotalClusterVM/Host"          $VMsPerHost    |
Add-Member -pass NoteProperty "TotalClusterpCPUSocket"          $TpCPUSocket   |
Add-Member -pass NoteProperty "TotalClusterpCPUCore"          $pCPUCore   |
Add-Member -pass NoteProperty "TotalClustervCPUCount"          $VCPU    |
Add-Member -pass NoteProperty "TotalClustervCPU/pCPUCore"          $vcpuperpcpucore  |
Add-Member -pass NoteProperty "TotalClustervCPU/pCPUCore After 1 Failover"          $TotalClustervcpuperpcore_FailoverOne  |
Add-Member -pass NoteProperty "TotalClustervCPU/pCPUCore After 2 Failvoer"          $TotalClustervcpuperpcore_Failovertwo  |
Add-Member -pass NoteProperty "TotalClusterRAMGB"          $TotalClusterRAMGB    |
Add-Member -pass NoteProperty "TotalClusterRAMGB_Failover1"          $TotalClusterRAMFailoverOne    |
Add-Member -pass NoteProperty "TotalClusterRAMGB_failover2"          $TotalClusterRAMFailvoerTwo    |
Add-Member -pass NoteProperty "TotalClusterRAMUSAGEPercent"          $TotalClusterRAMUsagePercent    |
Add-Member -pass NoteProperty "TotalClusterRAMUsageGB"     $TotalClusterRAMusageGB    |
Add-Member -pass NoteProperty "TotalClusterRAMFreeGB"      $TotalClusterRAMfreeGB    |
Add-Member -pass NoteProperty "TotalClusterRAMReservedGB(15%)"          $TotalClusterRAMReservedGB    |
Add-Member -pass NoteProperty "RAM Available for NEW VMs in GB"          $TotalClusterRAMAvailable    |
Add-Member -pass NoteProperty "RAM Available for NEW VMs in GB After 1 failover"          $TotalClusterRAMAvailable_FailoverOne    |
Add-Member -pass NoteProperty "RAM Available for NEW VMs in GB After 2 failover"          $TotalClusterRAMAvailable_FailoverTwo    |
Add-Member -pass NoteProperty "Allocated RAM per VM on an average"                          $avgrampervm    |
Add-Member -pass NoteProperty "NEW VM's that can be provisioned based on Average RAM per VM"                          $newvmcount    |
Add-Member -pass NoteProperty "NEW VM's that can be provisioned based on Average RAM per VM After 1 failover"          $newvmcount_failover1    |
Add-Member -pass NoteProperty "NEW VM's that can be provisioned basde on Average RAM per VM After 2 Failover"          $newvmcount_failover2   
 
}
 
get-cluster $cluster | get-vmhost | % {
$vmhost =$_
$VMHostView = $VMHost | Get-View
$VMHostModel      = ($VMHostsView | % { $_.Hardware.SystemInfo } | Group-Object Model | Sort -descend Count | Select -first 1).Name
$VMs = $VMHost | Get-VM #| ? { $_.PowerState -eq "PoweredOn" }
$TotalRAMGB       = [math]::round($vmhost.MemoryTotalGB)
$TotalRAMUsageGB       = [math]::round($vmhost.MemoryUsageGB)
$TotalRAMfreeGB       = [math]::round($TotalRAMGB-$TotalRAMUsageGB)
$PercRAMUsed     = [math]::round(($TotalRAMUsageGB/$TotalRAMGB)*100)
$TotalRAMReservedFree   = [math]::round(($TotalRAMGB/100)*15)
$TotalRAMAvailable   = [math]::round(($TotalRAMfreegb-$totalramreservedfree))
New-Object PSObject |
Add-Member -pass NoteProperty "VMhost"          $vmhost.Name    |
Add-Member -pass NoteProperty Model          $vmhostmodel    |
Add-Member -pass NoteProperty Sockets $VMHostView.Hardware.cpuinfo.NumCPUPackages   |
Add-Member -pass NoteProperty Cores   $VMHostView.Hardware.cpuinfo.NumCPUCores      |
Add-Member -pass NoteProperty Threads $VMHostView.Hardware.cpuinfo.NumCPUThreads    |
Add-Member -pass NoteProperty VMCount (($VMs | measure-object).Count)               |
Add-Member -pass NoteProperty vCPU    (0 + ($VMs | measure-object -Sum NumCPU).Sum) |
Add-Member -pass NoteProperty vCPUperCore ((0 + ($VMs | measure-object -Sum NumCPU).Sum)/$VMHostView.Hardware.cpuinfo.NumCPUCores) |
Add-Member -pass NoteProperty "RAMGB"           $TotalRAMGB            |
Add-Member -pass NoteProperty "RAMUsageGB"           $totalramusageGB            |
Add-Member -pass NoteProperty "RAMFreeGB"           $totalramfreeGB            |
Add-Member -pass NoteProperty "RAMUsage%"             $PercRAMused    |
Add-Member -pass NoteProperty "RAMReservedGB(15%)"           $totalramreservedfree            |
Add-Member -pass NoteProperty "RAM Available for NEW VMs in GB"           $totalramavailable
} | sort VMhost | ft -auto * | Out-String -Width 1024 >> cluster-stats.txt