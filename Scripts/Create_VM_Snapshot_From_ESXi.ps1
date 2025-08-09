#"" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File "D:\Abhishek\Lab\ESXi-Psw.txt"

$User = "root"
$File = "D:\Abhishek\Lab\ESXi-Psw.txt"
$MyCredential=New-Object -TypeName System.Management.Automation.PSCredential `
 -ArgumentList $User, (Get-Content $File | ConvertTo-SecureString)

$connection = Connect-VIServer -Server 192.168.1.51 -Credential $MyCredential -Force
$VMHost = Get-VMHost
$vmNames = "GB20250161","GB20250162","GB20250163","GB20250164","GB20250165","GB20250166","GB20250167";

foreach($vmName in $vmNames)
{

    $vm = $VMHost | get-vm -name $vmName;

    $vm | New-Snapshot -Name "Initial Snapshot" -Confirm:$false
}
