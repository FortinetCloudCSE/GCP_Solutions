terraform {
  required_version = ">= 1.0.0"

  required_providers {
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}
