# Initial Terraform + Proxmox Setup

terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = ">= 2.9.0"
    }
  }
}

variable "PM_API_TOKEN_ID" {
  type        = string
  description = "Proxmox API Token ID"
}

variable "PM_API_TOKEN_SECRET" {
  type        = string
  description = "Proxmox API Token Secret"
}

provider "proxmox" {
  pm_api_url          = "https://192.168.1.220:8006/api2/json"
  pm_user             = "root@pam"
  pm_api_token_id     = var.PM_API_TOKEN_ID
  pm_api_token_secret = var.PM_API_TOKEN_SECRET
}


### Setup VMs for each student ###

locals {
  # Load student data from the JSON file
  student_data = jsondecode(file("${path.module}/students.json"))

  # Extract student IDs and names
  all_student_ids   = [for student in local.student_data.students : student.student_id]
  all_student_names = [for student in local.student_data.students : student.student_name]
}

output "users" {
  value = local.all_student_ids
}

# Provision a VM for each student using count and sequential IP assignment
resource "proxmox_vm_qemu" "student_vm" {
  count       = length(local.all_student_ids)
  name        = "vm-${local.all_student_names[count.index]}"
  target_node = "proxmox-node"
  clone       = "ubuntu-template"

  cores       = 2
  memory      = 2048

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Sequential IP assignment starting from 192.168.1.128
  ipconfig0 = "ip=192.168.1.${128 + count.index}/24,gw=192.168.1.1"

  # Use student_id as the ssh user
  ssh_user   = local.all_student_ids[count.index]

  # Provisioner to force password change on first login
  provisioner "remote-exec" {
    inline = [
      "echo '${local.all_student_ids[count.index]}:temporary_password' | sudo chpasswd",
      "sudo chage -d 0 ${local.all_student_ids[count.index]}"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
      host        = self.network.0.ipconfig0.split('=')[1].split('/')[0]
    }

}