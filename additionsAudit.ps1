Import-Module .\CWManage.psm1
Import-Module .\password.ps1
	
	function Start-CWMConnection
	{
		# This is the URL to your manage server.
		$Server = $myServer

		# This is the company entered at login
		$Company = $myCompany

		#Public and private key created in connectwise manage
		$pubkey = $mypubkey
		$privatekey = $myprivatekey

		#ClientID created from https://developer.connectwise.com/ClientID
		$clientId = $myclientId


		# Connect to Manage server
		$Connection = @{
					Server = $Server
					Company = $Company 
					pubkey = $pubkey
					privatekey = $privatekey
					clientId = $clientId
				}
		Connect-CWM @Connection
		Write-Output "Authenticated successfully with Manage"
	} 

Start-CWMConnection

#get relevant agreements
$agree = Get-CWMAgreement -all -Condition 'type/name != "Break Fix" and type/name != "zz-TBS installs" and type/name != "TBS Install"' #and type/name != "3cx AMC + Base" and type/name != "zz-TBS installs" and company/identifier != "XYZTestCompany" and noEndingDateFlag = TRUE and name != "Monthly - Veeam O365" and name != "Monthly - Rack Space Rental" and name != "Custom Quote" and company/identifier != "CloudConnectPtyLtd"'  

$agree | Export-Csv -Path .\allAgree.csv
#company dictionary
$d = @{}

foreach($entry in $agree){
	
	#loop through agreements and add it to the corresponding company in the dictionary
	if($d[$entry.company.identifier] -eq $null)
	{	
		$addition = Get-CWMAgreementAddition $entry.id -all -Condition 'product/identifier = "CC-SSD" or product/identifier = "CC-RAM" or product/identifier = "CC-CPU"' 
	
		if($addition.count -ne 0)
		{
			$d.Add($entry.company.identifier, $addition)
		}
	}
	else {
	
		$addition = Get-CWMAgreementAddition $entry.id -all -Condition 'product/identifier = "CC-SSD" or product/identifier = "CC-RAM" or product/identifier = "CC-CPU"' 
		
		if($addition.count -ne 0)
		{
		
			$prevAddition = $d[$entry.company.identifier]
			
			$allAddition = $addition + $prevAddition
			
			
			$d[$entry.company.identifier] = $allAddition
		}
	}
}
	
#output object
$output = @{}

#loop through dictionary to sum up each CC-SSD, CC-RAM, CC-CPU if there are multiple agreement add-ons
$d.GetEnumerator() | sort value -Descending | ForEach-Object{

	$companyName = $_.name
	$identifier = $_.value.product.identifier
	$quantity = $_.value.quantity
	
	
	#write-output $companyName 
	#write-output $identifier 
	#write-output $quantity 
	
	$sumAddons = @{}
	
	for ($i=0; $i -le $identifier.count-1; $i++) {
	
		if($sumAddons[$identifier[$i]] -eq $null)
		{
			#bug caused if there is only a single entry
			if($identifier.count -eq 1)
			{
				$sumAddons.add($identifier,$quantity[$i])
			}
			else
			{
				$sumAddons.add($identifier[$i],$quantity[$i])
			}
			
		}
		else 
		{
			$prev = $sumAddons[$identifier[$i]]
			
			#bug caused if there is only a single entry
			if($identifier.count -eq 1)
			{
				$sumAddons[$identifier] = $prev + $quantity[$i]
			}
			else{
				$sumAddons[$identifier[$i]] = $prev + $quantity[$i]
			}
		}
		
    }
	
	$output.Add($_.name, $sumAddons)
}


$output.GetEnumerator() | sort value -Descending | ForEach-Object{
	
	#add-content -Value $_.name -path .\agree.csv
	
	#add-content -value $output[$_.name] -path .\agree.csv
	
	write-output $_.name
	write-output $output[$_.name]
	
	#add-content -Value $_.name -path .\agree.csv
	
	
}



###compare with hyperv report server03
## .\Get-HyperVReport.ps1 -Cluster P1-CL01




