output "server_address" {
    value = "${google_compute_instance.bedrock.0.network_interface.0.address}"
}
