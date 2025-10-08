# Create a new container registry
resource "digitalocean_container_registry" "smoke" {
  name                   = "smoke"
  subscription_tier_slug = "starter"
  region                 = var.region
}