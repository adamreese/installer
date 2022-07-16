variable "domain" {
  type        = string
  default     = "local.fermyon.link"
  description = "hostname"
}

variable "bindle_url" {
  type        = string
  default     = "http://bindle.local.fermyon.link/v1"
  description = "The Bindle server URL"
}

variable "hippo_version" {
  type        = string
  default     = "v0.17.0"
  description = "Hippo version"
}

job "hippo" {
  datacenters = ["dc1"]
  type        = "service"

  group "hippo" {
    network {
      port "http" {
        static = 5309
      }
    }

    service {
      name = "hippo"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.hippo.rule=Host(`hippo.${var.domain}`)",
      ]

      check {
        name     = "alive"
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "hippo" {
      driver = "raw_exec"

      artifact {
        source = "https://raw.githubusercontent.com/adamreese/installer/binary/aarch64/hippo/v0.17.0/hippo-server-linux-arm64.tar.gz"
      }

      artifact {
        source = "https://gist.githubusercontent.com/bacongobbler/48dc7b01aa99fa4b893eeb6b62f8cd27/raw/fb4dae8f42bc6aea22b2566084d01fa0de845e7c/styles.css"
      }

      artifact {
        source      = "https://gist.githubusercontent.com/bacongobbler/48dc7b01aa99fa4b893eeb6b62f8cd27/raw/fb4dae8f42bc6aea22b2566084d01fa0de845e7c/logo.svg"
        destination = "local/linux-arm64/wwwroot/assets/"
      }

      artifact {
        source = "https://gist.githubusercontent.com/bacongobbler/48dc7b01aa99fa4b893eeb6b62f8cd27/raw/fb4dae8f42bc6aea22b2566084d01fa0de845e7c/config.json"
      }

      artifact {
        source      = "https://www.fermyon.com/favicon.ico"
        destination = "local/linux-arm64/wwwroot/assets/"
      }

      env {
        Hippo__PlatformDomain = var.domain
        Scheduler__Driver     = "nomad"
        Nomad__Driver         = "raw_exec"

        Database__Driver            = "sqlite"
        ConnectionStrings__Database = "Data Source=hippo.db;Cache=Shared"

        Bindle__Url = var.bindle_url

        Jwt__Key      = "ceci n'est pas une jeton"
        Jwt__Issuer   = "localhost"
        Jwt__Audience = "localhost"

        Kestrel__Endpoints__Https__Url = "http://${NOMAD_ADDR_http}"
      }

      config {
        command = "bash"
        args    = ["-c", "cp local/styles.css local/linux-arm64/wwwroot/ && cp local/config.json local/linux-arm64/wwwroot/assets/ && cd local/linux-arm64 && ./Hippo.Web"]
      }
    }
  }
}
