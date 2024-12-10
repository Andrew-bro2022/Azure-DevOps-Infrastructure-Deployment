
# **DevOps Test Infrastructure Deployment**


This repository contains the necessary configurations and instructions to deploy a virtual machine (VM) on **Azure** using **Terraform (v1.6.6 or later)**. The system includes user management, disk setup, and basic configurations through **cloud-init** and **Ansible**. The VM will run either **AlmaLinux 9.x** or **Rocky Linux 9.x**, configured with a **30GB root volume** and an additional **15GB data volume** mounted at `/var/lib/docker`.

**Key Features:**

- **Operating System**: AlmaLinux 9.x or Rocky Linux 9.x (configurable via variables).
- **Storage Layout**:
  - 30GB root volume.
  - 15GB data volume mounted at `/var/lib/docker`.
- **User Management via cloud-init**:
  - A `deployuser` account (with a configurable UID) that has passwordless sudo rights.
  - 10 non-privileged guest accounts (`guest01` through `guest10`).
- **Security**:
  - Public/Floating IP assigned to the VM.
  - Security Group rules to restrict SSH access to specified IP ranges.
- **Configuration Management**:
  - **cloud-init**: Formats the `/var/lib/docker` volume as XFS, creates users, and performs initial setup.
  - **Ansible**: Used optionally after deployment to:
    - Fully update all RPM packages.
    - Set the VM hostname to `devopstest.driirn.ca`.
    - Set the timezone to Toronto/EST (UTC-5).

**Instructions are provided below on how to customize disk sizes, user access, allowed SSH CIDR, and more.**

---

## **Table of Contents**

1. [Prerequisites](#prerequisites)
2. [Repository Structure](#repository-structure)
3. [File Structure Details](#file-structure-details)
4. [Deployment Steps](#deployment-steps)
5. [Customizing the Deployment](#customizing-the-deployment)
6. [Cleaning Up Resources](#cleaning-up-resources)
7. [Known Issues](#known-issues)

---

## **Prerequisites**

Before deploying the system, ensure you have the following installed and configured on your machine:

- **Azure CLI**: [Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
  - Ensure you are logged into your Azure account:  
    ```bash
    az login
    ```
- **Terraform (v1.6.6 or later)**: [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- **Ansible (optional)**: Used for additional configurations like hostname and timezone setup.  
  [Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- **SSH Key Pair**: Ensure you have an SSH public/private key pair (e.g., `~/.ssh/id_rsa.pub`).

---

## **Repository Structure**

The repository is structured as follows:

```plaintext
.
├── main.tf              # Main Terraform configuration file
├── variables.tf         # Variables for Terraform
├── outputs.tf           # Terraform output definitions
├── cloud-init.yaml      # Cloud-init configuration for initial system setup
├── ansible/             # Directory for Ansible configurations
│   ├── inventory.ini    # Ansible inventory file for managing VM IPs
│   └── playbook.yml     # Ansible playbook for additional configurations
├── README.md            # Documentation for deployment and usage
```

---

## **File Structure Details**

### **main.tf**
Defines the main Terraform configuration to:
- Create an Azure Resource Group, Virtual Network, Subnet, Public IP, and NSG.
- Deploy an AlmaLinux 9.x or Rocky Linux 9.x VM.
- Attach an additional 15GB data disk to the VM for `/var/lib/docker`.

### **variables.tf**
Defines customizable variables for the deployment, including:
- Azure region (`location`).
- Allowed SSH CIDR (`allowed_ssh_cidr`).
- SSH public key (`ssh_public_key`).

### **outputs.tf**
Defines Terraform outputs, such as:
- The public IP address of the deployed VM (`public_ip`).

### **cloud-init.yaml**
Used to:
- Format and mount the additional disk as an XFS volume on `/var/lib/docker`.
- Create `deployuser` with passwordless sudo access.
- Create non-privileged users (`guest01` to `guest10`).

### **ansible/**
A directory containing:
- `inventory.ini`: An inventory file specifying the VM's public IP for Ansible.
- `playbook.yml`: An Ansible playbook to:
  - Update all system packages.
  - Set the VM hostname to `devopstest.driirn.ca`.
  - Set the timezone to `America/Toronto` (EST).

### **README.md**
This file contains step-by-step instructions for deploying and managing the system.

---

## **Deployment Steps**

### **1. Clone the Repository**
```bash
git clone https://github.com/yourusername/devopstest-infra.git
cd devopstest-infra
```

### **2. Initialize Terraform**
Initialize the Terraform environment to download the necessary providers:
```bash
terraform init
```

### **3. Customize Variables (Optional)**
You can customize variables by editing the `variables.tf` file or passing them as CLI arguments during deployment. Key variables include:

- `location`: Azure region (default: `eastus`).
- `allowed_ssh_cidr`: CIDR block for allowed SSH access (default: `0.0.0.0/0`).
- `ssh_public_key`: Your SSH public key for VM access.

### **4. Deploy the Infrastructure**
Run the following command to deploy the system:
```bash
terraform apply -var="allowed_ssh_cidr=<YOUR_IP_CIDR>" -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
```

Terraform will display a plan. Type `yes` to confirm and apply the configuration.

### **5. Retrieve the Public IP**
Once the deployment is complete, retrieve the VM's public IP address:
```bash
terraform output public_ip
```

### **6. Configure the System with Ansible (Optional)**
If Ansible is installed, perform additional configurations:

#### Update the `inventory.ini` File
Replace `<public_ip_output>` with the VM's public IP address:
```ini
[devops]
<public_ip_output> ansible_user=deployuser ansible_ssh_private_key_file=~/.ssh/id_rsa
```

#### Run the Ansible Playbook
Run the playbook to set the hostname, timezone, and update the system:
```bash
ansible-playbook -i ansible/inventory.ini playbook.yml
```

---

## **Customizing the Deployment**

### **Adjust Data Disk Size**
To adjust the size of the additional data disk mounted at `/var/lib/docker`, modify the `data_disk { disk_size_gb }` value in `main.tf`:
```hcl
data_disk {
  lun                  = 0
  caching              = "ReadWrite"
  storage_account_type = "Standard_LRS"
  disk_size_gb         = 20  # Adjust size here
  create_option        = "Empty"
}
```
Reapply the changes with:
```bash
terraform apply
```

### **Security Group Rules**
To restrict SSH access to specific IP ranges, modify the `allowed_ssh_cidr` variable during deployment or edit the `variables.tf` file.

---

## **Cleaning Up Resources**

To avoid incurring unnecessary charges, destroy all resources when no longer needed:
```bash
terraform destroy
```
Terraform will prompt for confirmation before destroying the resources.

---

## **Known Issues**

1. **Data Disk Mounting**:  
   Ensure the device path for the data disk (e.g., `/dev/sdc`) is correct in the `cloud-init.yaml`. Azure might assign different paths depending on the environment.

2. **SSH Connection Issues**:  
   If you cannot connect to the VM, verify:
   - The `allowed_ssh_cidr` includes your current IP.
   - Your SSH private key matches the public key used during deployment.

---



