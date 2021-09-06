# ESXi-Build-Inventory
This updated script will build multiple esxi host inventory sheet, its written in Powershell by using PowerCLI module of VMware. It will take the list of IP addresses of the ESXi hypervisors and fetch all required information such as:

1. Status
2. Server Vendor
3. Server Model
4. Serial Tag#
5. Server UUID
6. Hypervisor/VM OS Version
7. VMName on Hyp
8. Hostname
9. Hypervisor License
10. Processor Type
11. Hypervisor Licensable CPU
12. Hypervisor Licensable Cores
13. No. of CPU/Sockets
14. CPU Cores/Cores per Socket
15. CPU Threads/VCPUs
16. Allocated Memory GB
17. Usage Memory GB
18. Free Memory GB
19. Disk Path
20. Disk Capacity GB
21. Disk Free GB
22. Total Vms
23. Running Vms
24. PoweredOff Vms
25. ILOM/IDRAC IP Address
26. IP Addresses 

This script can be modified for various requirements. For successful execution, the VMware Tool should be installed for the Virtual Machines which you can verify from the GUI of the VMware ESXi hypervisors. The VM may be running but it failed to fetch the information just because of the unavailability of the VMware Tools. Furthermore, there is also a possibility that some cmdlets are not supported by the older version of ESXi or the assigned license.
![](https://github.com/mismailzz/VMware-ESXI-host-inventory/blob/main/Error-Info.PNG)

```
Powershell Version      
-------      
5.1.19041.906

PS C:\Users\mismailzz\Documents\Projects\HypervisorInventory> .\generate_inventory.ps1 -help

----------------------------HELP------------------------------------

-user		[Mention the user]

-ifile		[Mention the file path of IP addresses file]
		[For Example: C:\path\to\file.txt]

-ofile		[Mention the CSV output file]
		[For Example: C:\path\to\file.csv]

-help		[For Help]


***
Example Commands
PowerCLI C:\Users\user\Desktop> .\BuildInvetory.ps1 -help
PowerCLI C:\Users\user\Desktop> .\BuildInvetory.ps1 -user username -ifile C:\path\to\file.txt -ofile C:\path\to\file.csv
***


<!> WARNING <!>
<!> Please ensure to specify the correct password, if the password is not correct then
<!> after running this script continously with incorrect password may cause locking of your
<!> account on hypervisor


----------------- THE END --------------------
```

Just after the execution of the script, we have the Login portal

![](https://github.com/mismailzz/VMware-ESXI-host-inventory/blob/main/ESXI-login.PNG)

We can open the .csv file in the Excel format and modify it

![](https://github.com/mismailzz/VMware-ESXI-host-inventory/blob/main/ESXI-Inventory.PNG)


