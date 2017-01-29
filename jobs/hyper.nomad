
job "hyper" {

  datacenters = ["dc1"]

  type = "service"

  update {
    stagger      = "30s"
    max_parallel = 1
  }

  group "web" {

    count = 1

    task "ui" {

      driver = "docker"

      config {
        image = "hyper/docker-registry-web:latest"
        port_map {
          hyper = 8080
        }
      }

      env {
        REGISTRY_NAME = "docker-registry.service.consul:5000"
        REGISTRY_URL = "http://docker-registry.service.consul:5000/v2"
      }

      service {
        port = "hyper"
        tags = ["web"]
        check {
          type     = "tcp"
          port     = "hyper"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 500 # MHz
        memory = 512 # MB

        network {
          mbits = 100
          port "hyper" {}
        }
      }
    }
  }
}
