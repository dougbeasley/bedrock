

job "image-registry" {

  datacenters = ["dc1"]

  type = "service"

  update {
    stagger      = "30s"
    max_parallel = 1
  }

  group "registry-group" {

    count = 1

    ephemeral_disk {
      migrate = true
      size    = "1024"
      sticky  = true
    }

    task "registry" {

      driver = "docker"

      config {
        image = "registry:2"
      }

      service {
        name = "docker-registry"
        port = "registry"
        check {
          type     = "tcp"
          port     = "registry"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 500 # MHz
        memory = 128 # MB

        network {
          mbits = 100
          port "registry" {
            static = 5000
          }
        }
      }
    }
  }
}
