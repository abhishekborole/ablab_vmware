$VMHost = Get-VMHost
$DataStore = Get-Datastore -Name "Datastore-SSD-01"
$VMs = "Master1",
"Master2",
"Master3",
"Worker1",
"Worker2",
"Bootstrap"


$VMs | where {
$vmName = $_
#$vm = New-VM -Name $vmName `
#  -VMHost $VMHost `
#  -DiskGB 120 `
#  -DiskStorageFormat Thin `
#  -MemoryGB 16 `
#  -NumCpu 4 `
#  -Datastore $DataStore `
#  -NetworkName "Nested - Trunked" `
#  -GuestId "other3xLinux64Guest"
#
## Set the SCSI controller to ParaVirtual
#Get-ScsiController -VM $vm | Set-ScsiController -Type ParaVirtual
#
## Add CD/DVD drive and mount the ISO
#New-CDDrive -VM $vm -IsoPath "[Datastore-SSD-01] ISO/rhcos-4.19.0-x86_64-live-iso.x86_64.iso" -StartConnected
                               

get-vm $vmName |Start-VM

}