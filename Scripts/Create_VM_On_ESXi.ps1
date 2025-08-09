param (
    [Parameter(Mandatory = $true)]
    [string]$Hostname,
    [Parameter(Mandatory = $true)]
    [string]$Network,
    [Parameter(Mandatory = $true)]
    [string]$OS
)


if($OS.ToUpper() -eq "UBUNTU"){
    $OVF = "C:\OVF\Ubuntu\Ubuntu.ovf";
}
elseif($OS.ToUpper() -eq "RHEL"){
    $OVF = "C:\OVF\RHEL-9.6\RHEL-9.ovf";
}
else{
    exit;
}
# === Define the log file path with a timestamp ===
$Timestamp = (Get-Date).ToString("yyyy-MM-dd_HHmmss")
$LogFile = "C:\Scripts\Create-VM_$Timestamp.log"

# === Logger function ===
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $LogMessage = "$Timestamp $Level $Message"
    # Write to console
    Write-Host $LogMessage
    # Append to log file
    Add-Content -Path $LogFile -Value $LogMessage
}

# === Read Password ===
$secure = Get-Content "C:\Scripts\pwd.txt" | ConvertTo-SecureString
$psw = [System.Net.NetworkCredential]::new("", $secure).Password

# === Get Available IP Functionality ===

# Function to convert a byte array to an IP address
function ConvertTo-IP {
    param ([byte[]]$bytes)
    return [System.Net.IPAddress]::new($bytes)
}

# Function to check if an IP address is in use
function IPInUse {
    param ([System.Net.IPAddress]$ip)
    return $usedIPs -contains $ip
}

function Get-AvailableIP {

    param (
        [Parameter(Mandatory = $true)]
        [string]$Network
    )

    # Define the DHCP scope ID and the target computer name (DHCP server)
    $ScopeID = $Network
    $ComputerName = "localhost"

    # Retrieve the DHCP scope information for the specified scope ID
    $scope = Get-DhcpServerv4Scope -ComputerName $ComputerName | Where-Object { $_.ScopeId -eq $ScopeID }

    # Retrieve all leased and reserved IP addresses within the specified scope
    $leasedIPs = Get-DhcpServerv4Lease -ScopeId $ScopeID -ComputerName $ComputerName | Select-Object -ExpandProperty IPAddress
    $reservedIPs = Get-DhcpServerv4Reservation -ScopeId $ScopeID -ComputerName $ComputerName | Select-Object -ExpandProperty IPAddress

    # Combine leased and reserved IPs into a single list of used IPs
    $usedIPs = @()
    $usedIPs += $leasedIPs | ForEach-Object { $_.ToString() }
    $usedIPs += $reservedIPs | ForEach-Object { $_.ToString() }

    # Parse the start and end range of the DHCP scope into byte arrays
    $start = [System.Net.IPAddress]::Parse($scope.StartRange).GetAddressBytes()
    $end = [System.Net.IPAddress]::Parse($scope.EndRange).GetAddressBytes()

    # Iterate through the IP range to find an available IP address
    $IPAddress = $null
    for ($i = $start[3]; $i -le $end[3]; $i++) {
        $ipBytes = $start.Clone()
        $ipBytes[3] = [byte]$i
        $candidateIP = ConvertTo-IP $ipBytes

        if (-not (IPInUse $candidateIP)) {
            $IPAddress = $candidateIP.ToString()
            Write-Log -Message "Found available IP address: $IPAddress."
            return $IPAddress;        
        }
    }

    if (-not $IPAddress) {
        Write-Log -Message "No available IP address found in the subnet $Subnet." -Level "ERROR"
        throw "No available IP address found."
    }
}

# === VM Deployment Functionality ===

Write-Log -Message "Starting VM deployment for hostname: $Hostname."

try {
    $connection = Connect-VIServer -Server 192.168.1.51 -User root -Password $psw -Force
    Write-Log -Message "Connected to vSphere server 192.168.1.51."

    $VMHost = Get-VMHost
    Write-Log -Message "Retrieved VM host: $($VMHost.Name)."

    $DataStore = Get-Datastore -Name "Datastore-SSD-01"
    Write-Log -Message "Retrieved datastore: $($DataStore.Name)."
    
    Write-Log -Message "Using OVF file: $OVF."
    Import-VApp -Name $Hostname -Datastore $DataStore -VMHost $VMHost -DiskStorageFormat Thin -Source $OVF -Force
    Write-Log -Message "Imported OVF for VM: $Hostname."

    $VM = Get-VM $Hostname
    Write-Log -Message "Retrieved VM object for: $Hostname."

    #Get the Available IP
    $IPAddress = Get-AvailableIP -Network $Network

    # Calculate the gateway based on the IP address
    $IPParts = $IPAddress -split '\.'
    $Gateway = "$($IPParts[0]).$($IPParts[1]).$($IPParts[2]).254"
    Write-Log -Message "Calculated gateway for VM $($Hostname): $Gateway."

    # Configure advanced settings for the VM
    $VM | New-AdvancedSetting -Name "guestinfo.labvm.hostname" -Value $Hostname -Confirm:$false
    $VM | New-AdvancedSetting -Name "guestinfo.labvm.ipaddr" -Value $IPAddress -Confirm:$false
    $VM | New-AdvancedSetting -Name "guestinfo.labvm.gateway" -Value $Gateway -Confirm:$false
    $VM | New-AdvancedSetting -Name "guestinfo.labvm.subnet" -Value "24" -Confirm:$false
    $VM | New-AdvancedSetting -Name "guestinfo.labvm.dns" -Value "10.0.1.1" -Confirm:$false
    Write-Log -Message "Configured advanced settings for VM: $Hostname."

    $VM | Start-VM
    Write-Log -Message "Started VM: $Hostname."

    # === Reserve IP Address ===
    $MACAddress = ($VM | Get-NetworkAdapter).MacAddress.Replace(":","")
    Write-Log -Message "Retrieved MAC address for VM $($Hostname): $MACAddress."

    Add-DhcpServerv4Reservation -ScopeId $ScopeID -IPAddress $IPAddress -ClientId $MACAddress -Description "Reserved for $Hostname" -Name $Hostname
    Write-Log -Message "Reserved IP address $IPAddress for MAC address $MACAddress in DHCP scope $ScopeID."

} catch {
    Write-Log -Message "An error occurred: $_" -Level "ERROR"
    throw
} finally {
    Disconnect-VIServer -Server $connection -Confirm:$false
    Write-Log -Message "Disconnected from vSphere server."
    Write-Log -Message "Script execution completed."
}