param (
    [Parameter(Mandatory = $true)]
    [string]$Hostname,
    [Parameter(Mandatory = $true)]
    [string]$IPAddress
)

# Define the log file path with a timestamp
$Timestamp = (Get-Date).ToString("yyyy-MM-dd_HHmmss")
$LogFile = "C:\Scripts\Create-VM_$Timestamp.log"

# Logger function
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

# Start of the script
Write-Log -Message "Script execution started."

try {
    
    $connection = connect-viserver 192.168.1.51 -force -User root -password ""
    Write-Log -Message "Connected to vSphere server 192.168.1.51."

    $VMHost = Get-VMHost
    Write-Log -Message "Retrieved VM host: $($VMHost.Name)."

    $DataStore = Get-Datastore -Name "Datastore-SSD-01"
    Write-Log -Message "Retrieved datastore: $($DataStore.Name)."

    $OVF = "C:\OVF\Ubuntu\Ubuntu.ovf"
    Write-Log -Message "Using OVF file: $OVF."

    Write-Log -Message "Starting deployment for VM: $Hostname."

    # Calculate the gateway based on the IP address
    $IPParts = $IPAddress -split '\.'
    $Gateway = "$($IPParts[0]).$($IPParts[1]).$($IPParts[2]).254"
    Write-Log -Message "Calculated gateway for VM $($Hostname): $Gateway."

    Import-VApp -Name $Hostname -Datastore $DataStore -VMHost $VMHost -DiskStorageFormat Thin -Source $OVF -Force
    Write-Log -Message "Imported OVF for VM: $($Hostname)."

    $VM = Get-VM $Hostname
    Write-Log -Message "Retrieved VM object for: $($Hostname)."

    $VM | New-AdvancedSetting -Name "guestinfo.labvm.hostname" -Value $Hostname -Confirm:$false
    $VM | New-AdvancedSetting -Name "guestinfo.labvm.ipaddr" -Value $IPAddress -Confirm:$false
    $VM | New-AdvancedSetting -Name "guestinfo.labvm.gateway" -Value $Gateway -Confirm:$false
    $VM | New-AdvancedSetting -Name "guestinfo.labvm.subnet" -Value "24" -Confirm:$false
    $VM | New-AdvancedSetting -Name "guestinfo.labvm.dns" -Value "10.0.1.1" -Confirm:$false
    Write-Log -Message "Configured advanced settings for VM: $Hostname."

    $VM | Start-VM
    Write-Log -Message "Started VM: $Hostname."
} catch {
    Write-Log -Message "An error occurred: $_" -Level "ERROR"
    throw
} finally {
    Disconnect-VIServer -Server $connection -Confirm:$false
    Write-Log -Message "Disconnected from vSphere server."
    Write-Log -Message "Script execution completed."
}
# End of the script