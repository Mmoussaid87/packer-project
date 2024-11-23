packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

variable "cpu" {
  type    = string
  default = "2"
}

variable "disk_size" {
  type    = string
  default = "10000"
}

variable "domain" {
  type    = string
  default = "local"
}

variable "hostname" {
  type    = string
  default = "ubuntu"
}

variable "iso_checksum" {
  type    = string
  default = "e66de9baace72d53639daba0dce23126288d1a4ed0b9ebb55b163462cdda9a91"
}

variable "iso_url" {
  type    = string
  default = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
}

variable "name" {
  type    = string
  default = "ubuntu"
}

variable "ram" {
  type    = string
  default = "2048"
}

variable "ssh_password" {
  type    = string
  default = "ubuntu"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "version" {
  type    = string
  default = "2024"
}
variable "seed_image_path" {
  description = "Path to the cloud-init seed image for the environment"
  default     = "builders/kvm/cloud-init/testing/seed.img"
}

variable "output_directory" {
  description = "Directory where the built image will be stored"
  default     = "output/kvm/testing"
}


source "qemu" "ubuntu" {
  accelerator            = "kvm"
  disk_compression       = true
  disk_image             = true
  disk_size              = "${var.disk_size}"
  format                 = "qcow2"
  headless               = true
  iso_checksum           = "${var.iso_checksum}"
  iso_url                = "${var.iso_url}"
  net_device             = "virtio-net"
  output_directory       = "${var.output_directory}"
  qemuargs               = [["-machine", "accel=kvm"], ["-cpu", "host"], ["-m", "${var.ram}M"], ["-smp", "${var.cpu}"], ["-fda", "${var.seed_image_path}"], ["-serial", "mon:stdio"]]
  shutdown_command       = "echo '${var.ssh_password}' | sudo -S bash -c 'sleep 10 && /sbin/shutdown -P now'"
  ssh_handshake_attempts = "120"
  ssh_password           = "${var.ssh_password}"
  ssh_port               = "22"
  ssh_pty                = true
  ssh_timeout            = "10m"
  ssh_username           = "${var.ssh_username}"
  ssh_wait_timeout       = "0s"
  use_default_display    = true
  vm_name                = "${var.name}${var.version}.qcow2"
}

build {
  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    execute_command   = "{{ .Vars }} sudo -E bash '{{ .Path }}'"
    expect_disconnect = true
    inline            = ["sudo systemctl enable ssh", "sudo systemctl start ssh", "sudo apt update 2>&1 >/dev/null", "sudo apt -qq -y install software-properties-common git ansible 2>&1 >/dev/null"]
  }

}