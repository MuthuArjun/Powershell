<#

Check SNMP status on each ESXi host

Created by Jesse Evenson 12-3-14
#>

param ($esxuser = "root",
       $esxpass = $null
       )

$SNMPStatus = @()

if ($esxpass -eq $null)
    {
        "`nPlease enter a password with the -esxpass switch before running this script.`n"
        exit;
    }

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


# Get a list of all ESXi hosts from vCenter
Connect-VIServer vcenterhq -WarningAction SilentlyContinue
$vmhosts = Get-VMHost | select Name | sort Name
Disconnect-VIServer vcenterhq -Confirm:$false


foreach ($vmhost in $vmhosts)
    {
        $vmobj = "" | Select Host, "SNMP Enabled", Port, "SNMP String"
        $vmobj.Host = $vmhost.name

        # Connect to the esx host
        "`nConnecting to $($vmhost.name)"
        Connect-VIServer $vmhost.Name -User $esxuser -Password $esxpass -WarningAction SilentlyContinue

        # Get SNMP Settings
        $snmp = Get-VMHostSnmp 
        $vmobj.'SNMP Enabled' = $snmp.Enabled
        $vmobj.Port = $snmp.Port
        $vmobj.'SNMP String' = $snmp.ReadOnlyCommunities
        $vmobj | ft -AutoSize
        $SNMPStatus += $vmobj

        # If disabled, enabled SNMP
        if ($snmp.Enabled -eq $false)
            {
                Write-Host "SNMP is disabled on $($vmhost.name)... Enabling..."
                Get-VMHostSNMP | Set-VMHostSNMP -Enabled:$true -ReadOnlyCommunity '(!ns!ght)Read'
            }
        Disconnect-VIServer * -Confirm:$false
    }

#Disconnect-VIServer * -Confirm:$false

$SNMPStatus | ft -AutoSize
$SNMPStatus | Export-Csv SNMPStatus.csv