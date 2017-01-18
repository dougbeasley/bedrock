

provider "google" {
  region      = "${var.region}"
  project     = "${var.project_name}"
  credentials = "${file("${var.credentials_file_path}")}"
}

resource "google_compute_instance" "bedrock" {
    count = "${var.servers}"

    name = "bedrock-${count.index}"
    zone = "${var.region_zone}"
    tags = ["consul", "nomad", "bedrock"]

    machine_type = "${var.machine_type}"

    disk {
        image = "${lookup(var.machine_image, var.platform)}"
    }

    network_interface {
        network = "default"

        access_config {
            # Ephemeral
        }
    }

    metadata {
        ssh-keys = "${lookup(var.user, var.platform)}:${file("${var.public_key_path}")}"
    }

    service_account {
        scopes = ["https://www.googleapis.com/auth/compute.readonly"]
    }

    connection {
        user        = "${lookup(var.user, var.platform)}"
        private_key = "${file("${var.private_key_path}")}"
    }

    provisioner "file" {
        source      = "${path.module}/scripts/consul/${lookup(var.service_conf, var.platform)}"
        destination = "/tmp/consul-${lookup(var.service_conf_dest, var.platform)}"
    }

    provisioner "file" {
        source      = "${path.module}/scripts/nomad/${lookup(var.service_conf, var.platform)}"
        destination = "/tmp/nomad-${lookup(var.service_conf_dest, var.platform)}"
    }

    provisioner "remote-exec" {
        inline = [
            "echo ${var.servers} > /tmp/bedrock-server-count",
            "echo ${google_compute_instance.bedrock.0.network_interface.0.address} > /tmp/bedrock-server-addr",
        ]
    }

    provisioner "remote-exec" {
      inline = [
          "grep nameserver /etc/resolv.conf | sed 's/nameserver //' > /tmp/primary-dns"
      ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/scripts/dependencies.sh"
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/scripts/consul/install.sh",
            "${path.module}/scripts/consul/service.sh",
            "${path.module}/scripts/consul/ip_tables.sh",
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/scripts/nomad/install.sh",
            "${path.module}/scripts/nomad/service.sh",
            "${path.module}/scripts/nomad/ip_tables.sh",
        ]
    }

    provisioner "remote-exec" {
        inline = [
            "echo nameserver ${self.network_interface.0.address} | sudo tee -a /etc/resolvconf/resolv.conf.d/head",
            "sudo resolvconf -u",
         ]
    }
}

resource "google_compute_instance" "substrate" {

    count = "${var.clients}"

    name = "substrate-${count.index}"
    zone = "${var.region_zone}"
    tags = ["docker", "node", "substrate"]

    machine_type = "${var.machine_type}"

    disk = {
        image = "substrate-node-01182017"
    }

    network_interface {
        network = "default"

        access_config {
            # Ephemeral
        }
    }

    metadata {
        ssh-keys = "${lookup(var.user, var.platform)}:${file("${var.public_key_path}")}"
    }

    service_account {
        scopes = ["https://www.googleapis.com/auth/compute.readonly"]
    }

    connection {
        user        = "${lookup(var.user, var.platform)}"
        private_key = "${file("${var.private_key_path}")}"
    }

    provisioner "remote-exec" {
        inline = [
            "grep nameserver /etc/resolv.conf > /tmp/orig-nameserver",
            "echo ${join(",", google_compute_instance.bedrock.*.network_interface.0.address)} | tr , '\n' > /tmp/bedrock-nameservers",
            "sed -i -e 's/^/nameserver /' /tmp/bedrock-nameservers",
            "grep -v nameserver /etc/resolv.conf > /tmp/resolve.conf.new",
            "cat /tmp/bedrock-nameservers >> /tmp/resolve.conf.new && cat /tmp/orig-nameserver >> /tmp/resolve.conf.new",
            "sudo mv -f /tmp/resolve.conf.new /etc/resolv.conf"
        ]
    }
}


resource "google_compute_firewall" "consul_ingress" {
    name = "consul-internal-access"
    network = "default"

    allow {
        protocol = "tcp"
        ports = [
            "8300", # Server RPC
            "8301", # Serf LAN
            "8302", # Serf WAN
            "8400", # RPC
        ]
    }

    source_tags = ["consul"]
    target_tags = ["consul"]
}

resource "google_compute_firewall" "nomad_ingress" {
    name = "nomad-internal-access"
    network = "default"

    allow {
        protocol = "tcp"
        ports = [
            "4646", # HTTP
            "4647", # RPC
            "4648"  # Serf
        ]
    }

    source_tags = ["nomad"]
    target_tags = ["nomad"]
}
