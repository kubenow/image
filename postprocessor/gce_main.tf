#Google credentials, SSH Variables and current image version
variable gce_project {}
variable gce_zone {}
variable gce_credentials_file {}
variable ssh_user { default = "ubuntu" }
variable ssh_key {}
variable current_version {}

#Configure the Google Cloud provider
provider "google" {
  credentials = "${file("${var.gce_credentials_file}")}"
  project = "${var.gce_project}"
  region = "${var.gce_zone}"
}

#Defining the instance resource details
resource "google_compute_instance" "kubenow-image-export" {
  name         = "kubenow-image-export"
  machine_type = "n1-standard-4"
  zone         = "europe-west1-b"

  disk {
    image = "ubuntu-1604-xenial-v20170502"
    size = 20
  }

  #Local SSD disk
  disk {
    type    = "local-ssd"
    scratch = true
  }

  network_interface {
    network = "default"

    //Ephemeral IP - By leaving this block empty will generate a new external IP and assign it to the machine
    access_config {
    }
  }

  #SSH Settings
  metadata{
    sshKeys = "${var.ssh_user}:${file(var.ssh_key)} ${var.ssh_user}"
    ssh_user = "${var.ssh_user}"
  }

  #Provisioners: copying files so to be executed remotely on the VM instance
  provisioner "file" {
      source      = "../secrets-kubenow/host_cloud/aws.sh"
      destination = "/tmp/aws.sh"
      connection {
        type         = "ssh"
        user         = "${var.ssh_user}"
        agent        = "true"
      }
  }
  
  provisioner "file" {
      source      = "gce_tf.sh"
      destination = "/tmp/gce_tf.sh"
      connection {
        type         = "ssh"
        user         = "${var.ssh_user}"
        agent        = "true"
      }
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/gce_tf.sh",
      "/tmp/gce_tf.sh ${var.current_version}",
    ]
    connection {
        type         = "ssh"
        user         = "${var.ssh_user}"
        agent        = "true"
    }
  }
}