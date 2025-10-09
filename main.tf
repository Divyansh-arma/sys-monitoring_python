terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# Create a Kubernetes cluster

resource "digitalocean_kubernetes_cluster" "py-microservices-cluster" {
  name   = "py-microservices-cluster"
  region = var.region

  version = "latest"

  node_pool {
    name       = "python-app-pool"
    size       = "s-1vcpu-2gb"
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 2

  }
  registry_integration = true
}