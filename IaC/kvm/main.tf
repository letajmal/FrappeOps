terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.3"
    }
  }
}


provider "libvirt" {
  uri = "qemu:///system"
}

// blank 20GB image for net install.
resource "libvirt_volume" "controlplane2-qcow2" {
  name   = "controlplane2"
  pool   = "default"
  format = "qcow2"
  size   = 20000000000
  source =
}

resource "libvirt_domain" "domain-controlplane2" {
  name   = "controlplane2"
  memory = "4096"
  vcpu   = 2
  kernel = "casper/vmlinuz"
  initrd = "casper/initrd"

  network_interface {
    network_name = "default"
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.controlplane2-qcow2.id
  }

}
