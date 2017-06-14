# Openstack credentials and instance settings, SSH Variables and current image version
variable username {}
variable password {}
variable auth_url {}
variable user_domain_id {}
variable domain_id {}
variable region_name {}
variable project_id {}
variable tenant_id {}
variable tenant_name {}
variable auth_version {}
variable current_version {}
variable kubenow_image_name {}
variable kubenow_image_id {}
variable os_image_id {}
variable network_id {}

variable assign_floating_ip {
  default = false
}

variable os_pool_name {}

# SSH Settings
variable ssh_key_pub {}

variable ssh_user {
  default = "ubuntu"
}

# Create keypair resource to be used for ssh into instance
resource "openstack_compute_keypair_v2" "main" {
  name       = "${var.current_version}-keypair"
  public_key = "${file(var.ssh_key_pub)}"
}

# Create floating ip resource to be then associated to instance
resource "openstack_networking_floatingip_v2" "fip_1" {
  pool = "${var.os_pool_name}"
}

# No terraform provider as we are using environmental variables
# Directly defining the instance resource details.
resource "openstack_compute_instance_v2" "kubenow-image-export" {
  name            = "kubenow-image-export"
  image_id        = "${var.os_image_id}"
  flavor_name     = "8C-8GB-50GB"
  key_pair        = "${openstack_compute_keypair_v2.main.name}"
  security_groups = ["default"]
  floating_ip     = "${openstack_networking_floatingip_v2.fip_1.address}"

  network {
    uuid = "${var.network_id}"
  }

  # Provisioners: copying files so to be executed remotely on the VM instance
  provisioner "file" {
    source      = "../secrets-kubenow/host_cloud/aws.sh"
    destination = "/tmp/aws.sh"

    connection {
      type  = "ssh"
      user  = "${var.ssh_user}"
      agent = "true"
    }
  }

  provisioner "file" {
    source      = "../secrets-kubenow/host_cloud/CityCloud.sh"
    destination = "/tmp/citycloud.sh"

    connection {
      type  = "ssh"
      user  = "${var.ssh_user}"
      agent = "true"
    }
  }

  provisioner "file" {
    source      = "os_tf.sh"
    destination = "/tmp/os_tf.sh"

    connection {
      type  = "ssh"
      user  = "${var.ssh_user}"
      agent = "true"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/os_tf.sh",
      "/tmp/os_tf.sh ${var.kubenow_image_name} ${var.kubenow_image_id}",
    ]

    connection {
      type  = "ssh"
      user  = "${var.ssh_user}"
      agent = "true"
    }
  }
}
