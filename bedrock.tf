

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
        image = "substrate-node-01192017"
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

    primary_server = google_compute_instance.bedrock.0.network_interface.0.address
    consul_config = <<EOF
{
"data_dir" : "/opt/consul/data",
"log_level" : "DEBUG",
"server" : true,
"bootstrap_expect" :  ${count},
"start_join" : [${primary_server}]
}
EOF

    provisioner "file" {
      content = "${consul_config}"
      destination = "/etc/consul.d/server.json"
    }

    provisioner "remote-exec" {
      inline = [
          "grep nameserver /etc/resolv.conf | sed 's/nameserver //' | xargs printf  '{ \"recursors\" : [\"%s\"]}' > /etc/consul.d/primary-dns.json"
      ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/scripts/dependencies.sh"
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/scripts/consul/service.sh",
            "${path.module}/scripts/consul/ip_tables.sh",
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/scripts/nomad/service.sh",
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
        image = "substrate-node-01192017"
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
