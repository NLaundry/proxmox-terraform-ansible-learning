# VM orchestration in Proxmox with Terraform + Ansible

Goals:
- run Proxmox in a VM (nested VMs)
- use Terraform to provision VMs
- use Ansible to configure VMs

Test Machine:
- Debian Testing (Trixie as of October 8th 2024)
- AMD Ryzen 7 7700
- Nvidia GPU 3070
- Gnome DE 

Steps:
- [ ] Proxmox
    - [x] enable virtualization in BIOS
	- [x] enable nested virtualization
	- [x] download ISO
	- [x] setup in gnome boxes
	- [ ] basic config
	- [ ] 
	- [ ] 

## Proxmox setup

### Enable Virtualization in BIOS
#### Step 1: Restart the Computer
1. Reboot your computer.
2. During startup, press the appropriate key to enter the BIOS/UEFI setup. Common keys are:

   # #### Common Keys to Enter BIOS/UEFI
    - **Delete** (Del)
    - **F1**, **F2**, **F10**, **F12**
    - **Esc**
    - **ThinkPad** (Lenovo-specific systems sometimes use the ThinkPad button)
   
   The key should be displayed briefly during startup, such as "Press F2 to enter setup." Alternatively, you can check your system's manual for the exact key.

#### Step 2: Enter the BIOS/UEFI Setup
1. Press the key repeatedly during the initial boot screen until the BIOS/UEFI menu appears.
2. You will now be in the BIOS/UEFI utility.

#### Step 3: Locate Virtualization Setting
- Look for a tab like:

   # #### Possible Tabs to Find Virtualization Setting
    - **Advanced**
    - **CPU Configuration**
    - **System Configuration**
    - **Processor Settings**

These tabs often contain the CPU-related settings.

#### Step 4: Enable Virtualization Technology
- Find the option related to virtualization. The specific name may vary:

   # #### Virtualization Technology Option Names
    - For **Intel CPUs**, look for:
      - **Intel Virtualization Technology (VT-x)**
      - **VT-d** (for I/O virtualization support)
    - For **AMD CPUs**, look for:
      - **SVM Mode** or **AMD-V**

- Set this option to **Enabled**.

#### Step 5: Save Changes and Exit
1. After enabling virtualization, press **F10** or find the **Save & Exit** option.
2. Confirm changes to save and reboot the system.

##### Post-Reboot Verification
After the reboot, virtualization should be enabled. You can verify it by entering your operating system and checking virtualization support.

#### Notes
- Depending on your motherboard or system, virtualization may be listed under different sections. Refer to your manufacturer's documentation if you have trouble finding it.
  
   # #### Additional Settings
    - Some older systems may require enabling **Execute Disable Bit (XD)** or **No-Execute Memory Protection (NX)** for virtualization to function properly.

Once enabled, you can proceed with configuring your virtualization software, like KVM, VirtualBox, or VMware, on your Linux machine.

### Nested Virtualization

Enabling nested virtualization on a Linux machine depends on the virtualization technology you're using (e.g., KVM, VMware, etc.). Here's how to enable it for KVM, which is commonly used on Linux:

#### Step 1: Verify CPU Support for Virtualization
First, ensure your CPU supports nested virtualization:
- For Intel CPUs, look for the `vmx` flag.
- For AMD CPUs, look for the `svm` flag.

Run:
```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```
If the output is greater than 0, your CPU supports virtualization.

#### Step 2: Verify KVM Module
To check if KVM is loaded, run:
```bash
lsmod | grep kvm
```
You should see either `kvm_intel` or `kvm_amd` depending on your CPU.

#### Step 3: Enable Nested Virtualization

##### Intel CPU (`kvm_intel`)
To enable nested virtualization for Intel, run:
```bash
echo "options kvm-intel nested=Y" | sudo tee /etc/modprobe.d/kvm-intel.conf
```

##### AMD CPU (`kvm_amd`)
To enable nested virtualization for AMD, run:
```bash
echo "options kvm-amd nested=1" | sudo tee /etc/modprobe.d/kvm-amd.conf
```

#### Step 4: Reload KVM Module
Reload the KVM module to apply the changes:
```bash
sudo modprobe -r kvm_intel
sudo modprobe kvm_intel
```
or for AMD:
```bash
sudo modprobe -r kvm_amd
sudo modprobe kvm_amd
```

#### Step 5: Verify Nested Virtualization
To confirm that nested virtualization is enabled:
- For Intel:
  ```bash
  cat /sys/module/kvm_intel/parameters/nested
  ```
- For AMD:
  ```bash
  cat /sys/module/kvm_amd/parameters/nested
  ```
If it returns `Y` (for Intel) or `1` (for AMD), nested virtualization is enabled.

#### Note
- You may need to enable virtualization support in your BIOS/UEFI if it's not already enabled.
- After enabling nested virtualization, you may need to reboot the machine for changes to take full effect.

Let me know if you need more details on configuring this or anything else!

### Proxmox VM Install

- Download from: https://www.proxmox.com/en/downloads 
- Install in a VM: libvirt, VirtualBox, Gnome Boxes, etc.
- ridiculously easy ... just follow the GUI install process

### Terraform Install
- Can be installed on any machine that can access the Proxmox API
- I'm installing on on the server itself for simplicity
https://www.hashicorp.com/official-packaging-guide?product_intent=terraform

#### Debian Install process via APT 

they also have an appimage but I generally prefer to run through APT as much as possible

sudo apt update && sudo apt install gpg
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

- I'm on Debian testing so I had to manually change hashicorp.list back to bookworm instead of trixie

###  Configuration
- create an API key for proxmox
    - turn off priviliege separation for this key
    - if you don't, terraform gives you a very descriptive error about it

#TODO: Explain what the heck you did

### Getting a vm template

from proxmox web interface:
- on the left panel under data center
- drill down to the machine, storage volume - default is local, not local-lvm
- click on iso Images
- click upload (assuming you have one)
- i chose ubuntu 24.04 LTS for this example



#### Forward the port for the web interface | GAVE UP FOR NOW: installed bare metal instead
- Gnome boxes uses libvirt under the hood so you can edit those config files
- 
```xml
<devices>
  ...
  <interface type='network'>
    <mac address='...'/>
    <source network='default'/>
    <model type='virtio'/>
    <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    <port redir>
      <guest port='8006' host port='8006'/>
    </port redir>
  </interface>
  ...
</devices>
```

#### 


