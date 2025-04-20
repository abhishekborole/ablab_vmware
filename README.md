# ablab_vmware

This repository contains scripts and Ansible playbooks for managing VMware ESXi environments, including creating and managing virtual machines.

## Repository Structure
```
ablab_vmware/ 
    ├── Playbook/ │ 
        ├── Create_VM_On_ESXi.yaml │ 
        ├── Test_WinRM.yaml │ 
        ├── VMware-ESXi-List-VMs.yaml │ 
        ├── VMware-ESXi-VM-Create.yaml 
    ├── Scripts/ │ 
        ├── Build-UbuntuVM.ps1 
└── README.md
```
### Playbook Directory

This directory contains Ansible playbooks for various VMware ESXi operations:

- **`Create_VM_On_ESXi.yaml`**: Runs a PowerShell script on a remote Windows server to create VMs on ESXi.
- **`Test_WinRM.yaml`**: Tests WinRM connectivity to Windows hosts.
- **`VMware-ESXi-List-VMs.yaml`**: Retrieves a list of virtual machines from an ESXi server.
- **`VMware-ESXi-VM-Create.yaml`**: Deploys VMs from an OVF template on an ESXi server and configures advanced settings.

### Scripts Directory

This directory contains PowerShell scripts for VMware ESXi management:

- **`Build-UbuntuVM.ps1`**: Automates the creation of an Ubuntu VM on VMware ESXi using an OVF template. It also configures advanced settings like hostname, IP address, gateway, and DNS.

## Usage

### Prerequisites

- VMware ESXi server with appropriate credentials.
- Ansible installed on the control machine.
- PowerShell installed on the target Windows server for running scripts.
- Required Ansible collections:
  - `community.vmware`
  - `ansible.windows`

### Running Playbooks

1. Update the playbooks with the necessary variables, such as `esxi_host`, `esxi_user`, `esxi_password`, and `vm_list`.
2. Run the playbooks using the following command:
   ```bash
   ansible-playbook -i inventory Playbook/<playbook_name>.yaml
   ```

### Running PowerShell Scripts
1. Copy the script Build-UbuntuVM.ps1 to the target Windows server.
2. Execute the script with the required parameters:
```bash
powershell.exe -File "C:\Scripts\Build-UbuntuVM.ps1" -Hostname <VM_Hostname> -IPAddress <VM_IPAddress>
```
### License
This project is licensed under the MIT License.

### Author
Abhishek Borole