provider "kubernetes-alpha" {
  config_path = "~/.kube/config"
}

provider "google" {
  region  = "us-west1"
  zone    = "us-west1-a"
}

resource "google_compute_network" "demo_network" {
  name = "demo-network"
}

resource "kubernetes_manifest" "redis_instance" {
  provider = kubernetes-alpha

  depends_on = [
     google_compute_network.demo_network,
  ]

  manifest = {
    "apiVersion" = "redis.cnrm.cloud.google.com/v1beta1"
    "kind" = "RedisInstance"
    "metadata" = {
      "name" = "redisinstance-sample"
      "namespace" = "default"
    }
    "spec" = {
      "displayName" = "Sample Redis Instance"
      "region" = "us-west1"
      "tier" = "BASIC"
      "memorySizeGb" = 16
      "authorizedNetworkRef" = {
         "external" = google_compute_network.demo_network.self_link
      }
    }
  }
}
