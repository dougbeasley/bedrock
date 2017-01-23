
variable "project_name" {
  description = "The ID of the Google Cloud project"
  default     = "soapbox-cloud"
}

variable "credentials_file_path" {
  description = "Path to the JSON file used to describe your account credentials"
  default     = "~/.gcloud/soapbox-cloud.json"
}

variable "public_key_path" {
  description = "Path to file containing public key"
  default     = "~/.ssh/gcloud_id_rsa.pub"
}

variable "private_key_path" {
  description = "Path to file containing private key"
  default     = "~/.ssh/gcloud_id_rsa"
}

variable "region" {
    default     = "us-central1"
    description = "The region of Google Cloud where to launch the cluster"
}

variable "region_zone" {
    default     = "us-central1-f"
    description = "The zone of Google Cloud in which to launch the cluster"
}

variable "servers" {
    default     = "3"
    description = "The number of Consul servers to launch"
}

variable "clients" {
  default     = "3"
  description = "The number of client nodes to launch"
}

variable "machine_type" {
    default     = "f1-micro"
    description = "Google Cloud Compute machine type"
}
