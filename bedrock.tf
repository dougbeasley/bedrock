

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

    machine_type = "${var.machine_type["bedrock"]}"

    disk {
        image = "${var.machine_image["bedrock"]}"
    }

    network_interface {
        network = "default"

        access_config {
            # Ephemeral
        }
    }

    metadata {
        ssh-keys = "substrate:${file("${var.public_key_path}")}"
    }

    service_account {
        scopes = ["https://www.googleapis.com/auth/compute.readonly"]
    }

    connection {
        user        = "substrate"
        private_key = "${file("${var.private_key_path}")}"
    }

    provisioner "remote-exec" {
      inline = [
          "sudo mkdir /etc/consul.d",
          "sudo mkdir /etc/nomad.d",
          "grep nameserver /etc/resolv.conf | sed 's/nameserver //' | xargs printf  '{ \"recursors\" : [\"%s\"] }' | sudo tee /etc/consul.d/primary-dns.json",
          "echo ${google_compute_instance.bedrock.0.network_interface.0.address } | xargs printf '{ \"start_join\" : [\"%s\"]}' | sudo tee /etc/consul.d/start-join.json",
          "echo ${var.servers} | xargs printf '{ \"bootstrap_expect\" : %d }' | sudo tee /etc/consul.d/bootstrap-expect.json",
          "echo true | xargs printf '{ \"server\" : %s }' | sudo tee /etc/consul.d/server.json",
          "echo ${var.servers} | xargs printf '{ \"server\" : { \"bootstrap_expect\" : %d } }' | sudo tee /etc/nomad.d/bootstrap-expect.json",
      ]
    }

    provisioner "file" {
        source = "config/nomad/server.hcl"
        destination = "/tmp/nomad-server.hcl"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo mv /tmp/nomad-server.hcl /etc/nomad.d/server.hcl"
        ]
    }

    provisioner "file" {
        source = "config/systemd"
        destination = "/tmp"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo mv /tmp/systemd/* /etc/systemd/system"
        ]
    }

    provisioner "remote-exec" {
        inline = [
            "sudo systemctl daemon-reload",
            "sudo systemctl enable consul",
            "sudo systemctl enable nomad",
            "sudo systemctl start consul",
            "sudo systemctl start nomad"
        ]
    }
/*
    provisioner "remote-exec" {
        inline = [
            "echo nameserver ${self.network_interface.0.address} | sudo tee -a /etc/resolvconf/resolv.conf.d/head",
            "sudo resolvconf -u",
         ]
    }
*/
    provisioner "file" {
      content = "conf-dir=/etc/dnsmasq.d"
      destination = "/tmp/dnsmasq.conf"
    }

    provisioner "file" {
      source = "config/dnsmasq/consul-dns.conf"
      destination = "/tmp/consul-dns.conf"
    }

    provisioner "remote-exec" {
      inline = [
        "echo listen-address=${self.network_interface.0.address} | tee -a /tmp/consul-dns.conf",
        "sudo mv /tmp/dnsmasq.conf /etc/dnsmasq.conf",
        "sudo mv /tmp/consul-dns.conf /etc/dnsmasq.d",
        "sudo systemctl restart dnsmasq"
      ]
    }
}

resource "google_compute_instance" "substrate" {

    count = "${var.clients}"

    name = "substrate-${count.index}"
    zone = "${var.region_zone}"
    tags = ["docker", "node", "substrate"]

    machine_type = "${var.machine_type["substrate"]}"

    disk = {
        image = "${var.machine_image["substrate"]}"
    }

    network_interface {
        network = "default"

        access_config {
            # Ephemeral
        }
    }

    metadata {
        ssh-keys = "substrate:${file("${var.public_key_path}")}"
    }

    service_account {
        scopes = ["https://www.googleapis.com/auth/compute.readonly"]
    }

    connection {
        user        = "substrate"
        private_key = "${file("${var.private_key_path}")}"
    }

    provisioner "file" {
        source = "config/consul/client.json"
        destination = "/tmp/consul-client.json"
    }

    provisioner "file" {
        source = "config/nomad/client.hcl"
        destination = "/tmp/nomad-client.hcl"
    }

    provisioner "remote-exec" {
      inline = [
          "sudo mkdir /etc/consul.d",
          "sudo mkdir /etc/nomad.d",
          "sudo mv /tmp/consul-client.json /etc/consul.d/client.json",
          "sudo mv /tmp/nomad-client.hcl /etc/nomad.d/client.hcl"
      ]
    }

    provisioner "remote-exec" {
        inline = [
            "echo ${join(",", google_compute_instance.bedrock.*.network_interface.0.address)} | tr , '\n' > /tmp/bedrock-nameservers",
            "sed -i -e 's/^/nameserver /' /tmp/bedrock-nameservers",
            "cat /tmp/bedrock-nameservers | sudo tee -a /etc/resolvconf/resolv.conf.d/head",
            "sudo resolvconf -u",
         ]
    }

    provisioner "file" {
        source = "config/systemd"
        destination = "/tmp"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo mv /tmp/systemd/* /etc/systemd/system"
        ]
    }

    provisioner "remote-exec" {
        inline = [
            "sudo systemctl daemon-reload",
            "sudo systemctl enable consul",
            "sudo systemctl enable nomad",
            "sudo systemctl start consul",
            "sudo systemctl start nomad"
        ]
    }

}

resource "google_compute_instance" "internal-proxy" {

    count = 1

    name = "proxy-${count.index}"
    zone = "${var.region_zone}"
    tags = ["proxy", "node", "consul-ui"]

    machine_type = "${var.machine_type["internal-proxy"]}"

    disk = {
        image = "${var.machine_image["internal-proxy"]}"
    }

    network_interface {
        network = "default"

        access_config {
            # Ephemeral
        }
    }

    metadata {
        ssh-keys = "hydra:${file("${var.public_key_path}")}"
    }

    service_account {
        scopes = ["https://www.googleapis.com/auth/compute.readonly"]
    }

    connection {
        user        = "hydra"
        private_key = "${file("${var.private_key_path}")}"
    }

    provisioner "file" {
        source = "config/consul/client.json"
        destination = "/tmp/consul-client.json"
    }

    provisioner "remote-exec" {
      inline = [
          "sudo mkdir /etc/consul.d",
          "sudo mv /tmp/consul-client.json /etc/consul.d/client.json",
          "echo true | xargs printf '{ \"ui\" : %s }' | sudo tee /etc/consul.d/ui.json",
      ]
    }

    provisioner "remote-exec" {
        inline = [
            "echo ${join(",", google_compute_instance.bedrock.*.network_interface.0.address)} | tr , '\n' > /tmp/bedrock-nameservers",
            "sed -i -e 's/^/nameserver /' /tmp/bedrock-nameservers",
            "cat /tmp/bedrock-nameservers | sudo tee -a /etc/resolvconf/resolv.conf.d/head",
            "sudo resolvconf -u",
         ]
    }

    provisioner "file" {
        source = "config/systemd"
        destination = "/tmp"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo mv /tmp/systemd/* /etc/systemd/system"
        ]
    }

    provisioner "file" {
        source = "config/haproxy/haproxy.conf.tmpl"
        destination = "/tmp/haproxy.conf.tmpl"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo mv /tmp/haproxy.conf.tmpl /etc/haproxy"
        ]
    }

    provisioner "remote-exec" {
        inline = [
            "sudo systemctl daemon-reload",
            "sudo systemctl enable consul",
            "sudo systemctl start consul",
            "sudo systemctl enable consul-template",
            "sudo systemctl start consul-template"
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
