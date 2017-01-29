


job "hashi" {

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
        image = "jippi/hashi-ui:latest"
        port_map {
          hashi = 3000
        }
      }

      env {
        NOMAD_ADDR = "http://nomad.service.consul:4646"
        NOMAD_ENABLE = true
        CONSUL_ADDR = "consul.service.consul:8500"
        CONSUL_ENABLE = true
        LOG_LEVEL = "debug"
      }

      service {
        port = "hashi"
        tags = ["web"]
        check {
          type     = "tcp"
          port     = "hashi"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 500 # MHz
        memory = 256 # MB

        network {
          mbits = 100
          port "hashi" {}
        }
      }
    }
  }
}
