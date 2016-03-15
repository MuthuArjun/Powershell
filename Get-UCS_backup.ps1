####################################################
#
#   UCS Backup's
#   Creates backups of all UCS configs and stores
#   them on Coldhq1
#
#   This script requires the UCS Powershell module.
#
####################################################

if(!(Get-Module -Name CiscoUcsPS))
    {
        Import-Module CiscoUcsPS
    }
    
$pods="ucs1","ucs2","ucs-dr1"
$user="ucs-local\orion"
$pass=ConvertTo-SecureString "r6dghVez5KSL" -AsPlainText -Force
$cred=New-Object System.Management.Automation.PSCredential ($user,$pass)

foreach ($pod in $pods)
    {
        Connect-ucs $pod -Credential $cred
        
        #Full-state backup
        Write-Host "`nCreating full-state backup..."
        Backup-Ucs -Type full-state -PathPattern ‘C:\temp\ucs\${ucs}-${yyyy}_${MM}_${dd}-full-state.xml’

        #Config-Logical backup
        Write-Host "`nCreating config-logical backup..."
        Backup-Ucs -Type config-logical -PathPattern ‘C:\temp\ucs\${ucs}-${yyyy}_${MM}_${dd}-config-logical.xml’

        #Config-System backup
        Write-Host "`nCreating config-system backup..."
        Backup-Ucs -Type config-system -PathPattern ‘C:\temp\ucs\${ucs}-${yyyy}_${MM}_${dd}-config-system.xml’

        #Config-all backup
        Write-Host "`nCreating config-all backup..."
        Backup-Ucs -Type config-all -PathPattern ‘C:\temp\ucs\${ucs}-${yyyy}_${MM}_${dd}-config-all.xml’


        Disconnect-Ucs
    }

Move-Item -Path C:\Temp\ucs\ucs-2* -Destination \\cold1hq\g$\Replicated\UCSConfig\UCS1 -ErrorAction SilentlyContinue
Move-Item -Path C:\Temp\ucs\ucs2* -Destination \\cold1hq\g$\Replicated\UCSConfig\UCS2 -ErrorAction SilentlyContinue
Move-Item -Path C:\Temp\ucs\ucs-dr1* -Destination \\cold1hq\g$\Replicated\UCSConfig\UCS-dr1 -ErrorAction SilentlyContinue
Remove-Item C:\Temp\ucs\*

Write-Host "All UCS pods have been backed up."