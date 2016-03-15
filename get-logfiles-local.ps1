#$servers=@("ofx-sql","notifications1","LOS-macu1")
$file = "C:\Log_files.txt"

$server=$env:Computername
$local_disk = (GET-WMIOBJECT -query "SELECT * from win32_logicaldisk where DriveType = 3").DeviceID
$disk_count = $local_disk.count
$server_upper = $server.ToUpper()

Write-Host "`r`n--------------------`r`n   $server_upper`r`n--------------------`r`n"
"`r`n--------------------`r`n   $server_upper`r`n--------------------`r`n" >> $file

"There are $disk_count local disks on $server.`r`n" >> $file
Write-Host "There are $disk_count local disks on $server."
Write-Host "Scanning the disks for log files ...`r`n`r`n"

#$dir = gci \\$server\e$\ -Include *.log* -Recurse -ErrorAction SilentlyContinue | where {$_.DirectoryName -notlike "*windows*"}  | % {$_.DirectoryName} | Get-Unique

# Get the list of physical drives
foreach ($disk in $local_disk)
    {
        $ldisk= $disk.substring(0,1)
        Write-Host "Scanning the $ldisk drive...`r`n"
        
        $dir = gci $ldisk`:\ | where {$_.Name -notlike "Windows" -and $_.PSIsContainer} | where {$_.Name -notlike "Program Files*"} | gci -Include *.*log* -Recurse -ErrorAction SilentlyContinue | % {$_.DirectoryName} | Get-Unique
        #$dir = gci \\$server\$ldisk`$\ -Include *.log* -Recurse -ErrorAction SilentlyContinue | where {$_.DirectoryName -notlike "*windows*"}  | % {$_.DirectoryName} | Get-Unique
          
        # List the directories with lots of log files
        foreach ($d in $dir)
            {
                $stats = Get-ChildItem $d\* -Include *.log* -ErrorAction SilentlyContinue | Measure-Object -property length -sum
                $log_files = $stats.count
                $total_size = "{0:N2}" -f ($stats.sum / 1MB)

                if ($total_size -ge 10)
                    {
                        Write-Host "Directory: $d"
                        Write-Host "Contains $log_files log files"
                        Write-Host "Totaling $total_size MB. `r`n"

                        "Directory: $d" >> $file
                        "Contains $log_files log files" >> $file
                        "Totaling $total_size MB. `r`n" >> $file

                    }
               
            }

    }

 "`r`n`r`n" >> $file