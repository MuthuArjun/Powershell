$myCol = @()
ForEach ($VMHost in (Get-VMHost ucs1-06.mtnam.org))
	{
	ForEach ($VM in ($VMHost | Get-VM | Sort Name))
		{
		# Gather Stats
		$Ready = $VM | Get-Stat -Stat Cpu.Ready.Summation -RealTime
		$Used = $VM | Get-Stat -Stat Cpu.Used.Summation -RealTime
		$Wait = $VM | Get-Stat -Stat Cpu.VMWait.Summation -RealTime
		For ($a = 0; $a -lt $VM.NumCpu; $a++)
			{
			$myObj = "" | Select VMHost, VM, Instance, %RDY, %USED, %WAIT
			$myObj.VMHost = $VMHost.Name
			$myObj.VM = $VM.Name
			$myObj.Instance = $a
			$myObj."%RDY" = [Math]::Round((($Ready | Where {$_.Instance -eq $a} | Measure-Object -Property Value -Average).Average)/200,1)
			$myObj."%USED" = [Math]::Round((($Used | Where {$_.Instance -eq $a} | Measure-Object -Property Value -Average).Average)/200,1)
			$myObj."%WAIT" = [Math]::Round((($Wait | Where {$_.Instance -eq $a} | Measure-Object -Property Value -Average).Average)/200,1)
			$myCol += $myObj
			}
		Clear-Variable Ready -ErrorAction SilentlyContinue 
		Clear-Variable Wait -ErrorAction SilentlyContinue 
		Clear-Variable Used -ErrorAction SilentlyContinue 
		Clear-Variable myObj -ErrorAction SilentlyContinue
		}
	}