$auto = Get-ADComputer -SearchBase "OU=Servers - Auto Update,OU=Servers,DC=mtnam,DC=org" -Filter * | sort Name | select name
$needed = Get-Content C:\tools_needed.txt
foreach ($server in $needed)
    {
        if ($auto | where {$_.name -eq "$server"})
            {
                Write-Host "$server is in the auto-update OU.`n`n "
                $server >> c:\server_in_auto_update.txt
            }
        else {
            Write-Host "$server is not in the auto-update OU.`n`n "
            $server >> c:\server_not_in_auto_update.txt
             }
    }