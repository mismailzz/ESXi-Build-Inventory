param ([switch]$help, $user, $ifile, $ofile)


$currentDirectory = (Get-Location).Path
Import-Module $currentDirectory\Get-VMHostWSManInstance.psm1
Import-Module VMware.VimAutomation.Core

#HELP FUNCTION
function Help_fn(){ 

	write-host ""
	write-host "----------------------------HELP------------------------------------"
	write-host ""
	write-host "-user		[Mention the user]"
	write-host ""
	write-host "-ifile		[Mention the file path of IP addresses file]"
	write-host "		[For Example: C:\path\to\file.txt]"
	write-host ""
	write-host "-ofile		[Mention the CSV output file]"
	write-host "		[For Example: C:\path\to\file.csv]"
	write-host ""
	write-host "-help		[For Help]"
	write-host ""
	write-host ""
	write-host "***"
	write-host "Example Commands"
	write-host "PowerCLI C:\Users\user\Desktop> .\BuildInvetory.ps1 -help"
	write-host "PowerCLI C:\Users\user\Desktop> .\BuildInvetory.ps1 -user username -ifile C:\path\to\file.txt -ofile C:\path\to\file.csv"
	write-host "***"
	write-host ""
	write-host ""
	write-host "<!> WARNING <!>"
	write-host "<!> Please ensure to specify the correct password, if the password is not correct then"
	write-host "<!> after running this script continously with incorrect password may cause locking of your"
	write-host "<!> account on hypervisor"
	write-host ""
	write-host ""
}

#CREATE OUTPUT FILE
function Create_file($outputfile){

    #SETTING THE HEADER FIELDS OF THE OUTPUT FILE
	$ADDLINE = "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13},{14},{15},{16},{17},{18},{19},{20},{21},{22},{23},{24},{25}" -f "Status", "Server Vendor", "Server Model",	"Serial Tag#",	"Server UUID",	"Hypervisor/VM OS Version", "VMName on Hyp", "Hostname",	"Hypervisor License",	"Processor Type",	"Hypervisor Licensable CPU",	"Hypervisor Licensable Cores",	"No. of CPU/Sockets",	"CPU Cores/Cores per Socket",	"CPU Threads/VCPUs",	"Allocated Memory GB",	"Usage Memory GB",	"Free Memory GB", "Disk Path",	"Disk Capacity GB", "Disk Free GB", "Total Vms",	"Running Vms",	"PoweredOff Vms",	"ILOM/IDRAC IP Address",	"IP Addresses"
	$ADDLINE | add-content -path $outputfile


}

function ServerInfo($inputfile, $outputfile, $credential){

    

	foreach($serverIPAddress in [System.IO.File]::ReadLines($inputfile))
	{
		#CONNECT TO SERVER ESXI HYPERVISOR {ALSO CHECK THE CONNECTIVITY}
        if (Connect-VIServer $serverIPAddress -cred $credential)
        {
            
            $serverInfo = Get-VMHost -Server $serverIPAddress
            $serverHostname=$serverInfo.NetworkInfo.HostName

            #Server/HYP status Information
            $server=get-view -viewtype HostSystem
            #HYP
            $serverVendor=$server.Summary.Hardware.Vendor 
            $serverModel=$server.Summary.Hardware.Model
            $serverUUID=$server.Summary.Hardware.Uuid
            $serverHypervisor=$server.Summary.Config.Product.FullName
            #$serverHypVersion=$server.Summary.Config.Product.Version
            $serverLicense=(Get-VMHost -Server $serverIPAddress).LicenseKey
            #CPU
            $serverCpuModel=$server.Summary.Hardware.CpuModel
            $serverLicensableCpu=($server.LicensableResource.Resource | where {$_.Key -eq "numCpuPackages"}).Value
            $serverLicensableCores=($server.LicensableResource.Resource | where {$_.Key -eq "numCpuCores"}).Value
            
            $serverNumCpu=$server.Summary.Hardware.NumCpuPkgs
            $serverCpuCores=$server.Summary.Hardware.NumCpuCores
            $serverCpuThreads=$server.Summary.Hardware.NumCpuThreads
            
            #Memory
            $serverMemoryAllocated=(Get-VMHost -Server $serverIPAddress).MemoryTotalGB
            $serverMemoryUsage=(Get-VMHost -Server $serverIPAddress).MemoryUsageGB
            $serverMemoryFree=$serverMemoryAllocated-$serverMemoryUsage
            
            $serverMemoryFree=[math]::Round($serverMemoryFree,3)
            
            #DISK
            $storagePath = (get-datastore | select-object -property Name).Name -join " | "
            $storageCapacity = (get-datastore | select-object -property CapacityGB).CapacityGB -join " | "
            $storageFree = (get-datastore | select-object -property FreeSpaceGB).FreeSpaceGB -join " | "
            
            #VMs STAT
            $serverTotalVMs = (Get-VM -Server $serverIPAddress).count
            $serverRunningVMs = ((Get-VM -Server $serverIPAddress).where{$_.PowerState -eq "PoweredOn"}).count
            $serverPoweredOffVMs = ((Get-VM -Server $serverIPAddress).where{$_.PowerState -eq "PoweredOff"}).count
            

            
            $serialTag = ""
            #WE HAVE THE LIST IN WHICH TAGS REPEAT OR ON THE LAST OR OTHER RAW INFORMATION. SO WE HAVE TO PARSE IT 
            $stringTags = ((($serverInfo | Get-View).Summary.Hardware.OtherIdentifyingInfo | select IdentifierValue).IdentifierValue -join ";")
            $stringTags.Split(";") | ForEach {
            
            	$temp_tag = $_
            	
            	if($temp_tag -match '^[0-9A-Z]+$'){ # REGEX TO GET THE VALID TAG 
            		$serialTag = $temp_tag
                    #break
            	}
            }
            
            
            #CALLING THE ABOVE IMPORT MODULE FOR GETTING THE ILOM IP ADDRESS
            try {

                $info = Get-VMHostWSManInstance -VMHost (Get-VMHost $serverIPAddress) -ignoreCertFailures -class OMC_IPMIIPProtocolEndpoint
                $ilomIPAddress = $info.IPv4Address
            
            }
            catch
            {
                Write-Output $serverIPAddress
                Write-Warning -Message "Get-VMHostWSManInstance : Current license or ESXi version prohibits execution of the requested operation. {ILOM IP NOT FOUND}" 
                $info = ""
                $ilomIPAddress = ""
            }
		    
            if([string]::IsNullOrEmpty($ilomIPAddress)){$ilomIPAddress="IP Not Found"}


		    #ADDING SERVER AND ILOM INFORMATION IN FILE
		    $ADDLINE =  "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13},{14},{15},{16},{17},{18},{19},{20},{21},{22},{23},{24},{25}" -f "-","$serverVendor", "$serverModel", "$serialTag",	"$serverUUID", "$serverHypervisor", " ", "$serverHostname", "$serverLicense", "$serverCpuModel", "$serverLicensableCpu",	"$serverLicensableCores",	"$serverNumCpu",	"$serverCpuCores",	"$serverCpuThreads", "$serverMemoryAllocated",	"$serverMemoryUsage", "$serverMemoryFree", "$storagePath",	"$storageCapacity",	"$storageFree", "$serverTotalVMs",	"$serverRunningVMs", "$serverPoweredOffVMs", "$ilomIPAddress", "$serverIPAddress"
            $ADDLINE | add-content -path $outputfile

		    
            try {
                #GET THE LIST OF RUNNING VM'S ON HYPERVISOR IN STRING
                $runningVMs = ((Get-VM -Server $serverIPAddress).where{$_.PowerState -eq "PoweredOn"}) | Select-Object -Property Name 
                $listOfRunVMs = $runningVMs.Name -join ";"
                #SPLITTING AND ITERATING THE INDIVIDUAL VMS ALSO WITH DUMPING INFORMATION IN .CSV FILE
		        
		        $listOfRunVMs.Split(";") | ForEach {
		        
                    #try { #TO GET THE EXCEPTION WHILE FETCHING INFORMATION
                    
                     #write-output $_
		             $vmName = $_
		             $vminfo = Get-VMGuest -VM $vmName

		             $vmConnectionInfo = $vminfo.IPAddress -join " | " #TO COMBINE FOR MULTIPLE IP'S
                     $vmGetIPAddress = $vmConnectionInfo -replace '[a-z]+[0-9]*:*[0-9a-z]*:*[0-9a-z]*:*[0-9a-z]*:*[0-9a-z]*' -replace " "
                     $vmIPAddress = $vmGetIPAddress -replace "[\|]+"," | "

		                    
		             #DUMPING FETECHED INFORMATION
		             #$vmVCPUs = $vmSysInfo.NumCpu
                     #$corePerSocket = $vmSysInfo.CoresPerSocket
                     $vmVCPUs = (Get-VM $vmName).NumCpu
                     $corePerSocket = (Get-VM $vmName).CoresPerSocket
                     $vmSockets = $vmVCPUs/$corePerSocket
                     #$hardDiskInfo = (Get-HardDisk -VM $vmName).CapacityGB
                     $hardDiskInfo =  (Get-HardDisk -vm $vmName | Measure-Object -Property CapacityGB -Sum).Sum
                     $memoryGB = (Get-VM $vmName).MemoryGB
		             $ADDLINE = "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13},{14},{15},{16},{17},{18},{19},{20},{21},{22},{23},{24},{25}" -f "Running","-","-","-","-", $vminfo.OSFullName,$vmName,$vminfo.HostName,"-","-","-","-",$vmSockets,$corePerSocket,$vmVCPUs,$memoryGB,"-","-","-","$hardDiskInfo","-","-","-","-","-","$vmIPAddress"
                     $ADDLINE | add-content -path $outputfile

                    
                  }
                
                #----------------------
                #Replication of above
                #GET THE LIST OF Poweredoff VM'S ON HYPERVISOR IN STRING
                $poweredOffVMs = ((Get-VM -Server $serverIPAddress).where{$_.PowerState -eq "PoweredOff"}) | Select-Object -Property Name 
                $listOfPoweredOffVMs = $poweredOffVMs.Name -join ";"
                #SPLITTING AND ITERATING THE INDIVIDUAL VMS ALSO WITH DUMPING INFORMATION IN .CSV FILE
		        
		        $listOfPoweredOffVMs.Split(";") | ForEach {
		        
                    
                     #write-output $_
		             $vmName = $_
		             $ADDLINE = "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13},{14},{15},{16},{17},{18},{19},{20},{21},{22},{23},{24},{25}" -f "PoweredOff","-", "-", "-", "-", "-", $vmName, "-", "-", "-", "-", "-", "-",	"-", "-", "-", "-","-", "-", "-", "-",	"-", "-", "-", "-", "-", "-"
                     $ADDLINE | add-content -path $outputfile

                    
                  }
                  #-------------------------

		    }catch{
                Write-Warning $Error[0] 
            }

           

		    #DISCONNECTING THE SERVER ESXI HYPERVISOR
            #DON'T ALLOW THE PROMPT MESSAGE FOR YES OPTION
		    Disconnect-VIServer -Server $serverIPAddress -Force –Confirm:$false 
        
        }else{ 
            Write-Output "Info: PoweCLI does not connect to ESXI - " $serverIPAddress
      }
			
	}

}

#MAIN FUNCTION 

if ($help) {

	Help_fn
	
}elseif(![string]::IsNullOrEmpty($ifile) -and ![string]::IsNullOrEmpty($ofile) -and ![string]::IsNullOrEmpty($user)){

    $cred = Get-Credential $user 
	Create_file $ofile
	ServerInfo $ifile $ofile $cred

}else{
	write-host "Please pass the correct arguments"
}

write-host "----------------- THE END --------------------"
