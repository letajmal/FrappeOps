# VM

resource "google_compute_instance" "terra-1-r" {
  name         = "terra-1"
  machine_type = "e2-small"

  tags = ["terraform"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size = 10
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.terra-1-ip-r.address
    }
  }

  metadata = {
    ssh-keys = "ajmal: ${tls_private_key.terra-1-key-r.public_key_openssh}"
  }

  metadata_startup_script = <<EOF
    #!/bin/bash
    set -e
    # Install required packages using the system package manager
    apt-get update && apt-get install -y python3 ansible

    # Install Docker using a separate Ansible playbook
    /usr/bin/ansible-galaxy role install geerlingguy.docker

cat <<EOF2 > /root/docker.yml
- hosts: localhost
  roles:
    - role: geerlingguy.docker
      vars:
        docker_users: [ ajmal ]
EOF2

    # Run the Ansible playbook to configure Docker
    /usr/bin/ansible-playbook /root/docker.yml
EOF

}

# Public IP

resource "google_compute_address" "terra-1-ip-r" {
  name   = "terra-1-ip"
}

# Firewall

resource "google_compute_firewall" "terra-1-firewall-r" {
  project     = "river-module-413016"
  name        = "terra-1-firewall"
  network     = "default"
  description = "Creates firewall rule targeting tagged instances"

  allow {
    protocol  = "tcp"
    ports     = ["80", "443", "22"]
  }
  source_ranges = [ "0.0.0.0/0" ]
  target_tags = google_compute_instance.terra-1-r.tags
}

# Key

resource "tls_private_key" "terra-1-key-r" {
  algorithm = "ED25519"
}

output "private_key" {
  value     = tls_private_key.terra-1-key-r.private_key_openssh
  sensitive = true
}