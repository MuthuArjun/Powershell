<#

This script will perform a simple query on each of the 5 domain controllers 
and return a table with the response time for each.

#>

import-module ActiveDirectory

$DCs = "D83HQDC2","D83HQDC1","D83HQDC3","D83DRDC1","D83DRDC2"
$DC_response = @()


Foreach ($dc in $DCs)
    {
        $vmobj = "" | Select DC, "Response Time(ms)"
        $vmobj.DC = $DC
        $millisec = (Measure-Command { Get-ADUser -Server $dc jevenson } ).TotalMilliseconds
        $vmobj.'Response Time(ms)' = $millisec
        $DC_response += $vmobj
    }

$DC_response | sort DC | ft -AutoSize