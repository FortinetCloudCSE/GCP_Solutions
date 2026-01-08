locals {

  prefix = var.prefix

  region = var.region
  zone   = var.zone
  zone2  = var.zone2

  fortigate_machine_type = var.fortigate_machine_type
  fortigate_vm_image     = var.fortigate_vm_image


  fortigate_license_files = var.fortigate_license_files
  flex_tokens             = var.flex_tokens
  license_type            = var.license_type
  fgsp                  = var.fgsp

  #######################
  # Static IPs
  #######################

  compute_addresses = {
    "elb-static-ip" = {
      region       = local.region
      name         = "${local.prefix}-elb-static-ip-${random_string.string.result}"
      subnetwork   = null
      address      = null
      address_type = "EXTERNAL"
    }
    "fgt1-static-ip" = {
      region       = local.region
      name         = "${local.prefix}-fgt1-static-ip-${random_string.string.result}"
      subnetwork   = null
      address      = null
      address_type = "EXTERNAL"
    }
    "fgt2-static-ip" = {
      region       = local.region
      name         = "${local.prefix}-fgt2-static-ip-${random_string.string.result}"
      subnetwork   = null
      address      = null
      address_type = "EXTERNAL"
    }
    "ilb-ip" = {
      region       = local.region
      name         = "${local.prefix}-ilb-ip-${random_string.string.result}"
      subnetwork   = google_compute_subnetwork.compute_subnetwork["trust-subnet-1"].id
      address      = null
      address_type = "INTERNAL"
    }
    "fgt1-trust-ip" = {
      region       = local.region
      name         = "${local.prefix}-fgt1-trust-ip-${random_string.string.result}"
      subnetwork   = google_compute_subnetwork.compute_subnetwork["trust-subnet-1"].id
      address      = null
      address_type = "INTERNAL"
    }
    "fgt2-trust-ip" = {
      region       = local.region
      name         = "${local.prefix}-fgt2-trust-ip-${random_string.string.result}"
      subnetwork   = google_compute_subnetwork.compute_subnetwork["trust-subnet-1"].id
      address      = null
      address_type = "INTERNAL"
    }
    "fgt1-untrust-ip" = {
      region       = local.region
      name         = "${local.prefix}-fgt1-untrust-ip-${random_string.string.result}"
      subnetwork   = google_compute_subnetwork.compute_subnetwork["untrust-subnet-1"].id
      address      = null
      address_type = "INTERNAL"
    }
    "fgt2-untrust-ip" = {
      region       = local.region
      name         = "${local.prefix}-fgt2-untrust-ip-${random_string.string.result}"
      subnetwork   = google_compute_subnetwork.compute_subnetwork["untrust-subnet-1"].id
      address      = null
      address_type = "INTERNAL"
    }
  }

  #######################
  # Compute Networks
  #######################

  compute_networks = {
    "untrust-vpc" = {
      region                  = local.region
      name                    = "${local.prefix}-untrust-vpc-${random_string.string.result}"
      auto_create_subnetworks = false
      routing_mode            = "REGIONAL"
    }
    "trust-vpc" = {
      region                  = local.region
      name                    = "${local.prefix}-trust-vpc-${random_string.string.result}"
      auto_create_subnetworks = false
      routing_mode            = "REGIONAL"
    }
  }
  #######################
  # Compute Subnets
  #######################

  compute_subnetworks = {
    "untrust-subnet-1" = {
      region        = local.region
      network       = google_compute_network.compute_network["untrust-vpc"].id
      name          = "${local.prefix}-untrust-subnet-${random_string.string.result}"
      ip_cidr_range = "10.15.0.0/24"
    }
    "trust-subnet-1" = {
      region        = local.region
      network       = google_compute_network.compute_network["trust-vpc"].id
      name          = "${local.prefix}-trust-subnet-${random_string.string.result}"
      ip_cidr_range = "10.15.1.0/24"
    }
  }

  #######################
  # Compute Firewalls
  #######################

  compute_firewalls = {
    "untrust-vpc-ingress" = {
      name               = format("%s-ingress", google_compute_network.compute_network["untrust-vpc"].name)
      network            = google_compute_network.compute_network["untrust-vpc"].name
      direction          = "INGRESS"
      source_ranges      = ["0.0.0.0/0"]
      destination_ranges = null
      allow = [{
        protocol = "all"
      }]
    }
    "trust-vpc-ingress" = {
      name               = format("%s-ingress", google_compute_network.compute_network["trust-vpc"].name)
      network            = google_compute_network.compute_network["trust-vpc"].name
      direction          = "INGRESS"
      source_ranges      = ["0.0.0.0/0"]
      destination_ranges = null
      allow = [{
        protocol = "all"
      }]
    }
  }

  #######################
  # Compute disks
  #######################

  compute_disks = {
    "fgt1-logdisk" = {
      name = "fgt1-logdisk-${random_string.string.result}"
      size = 30
      type = "pd-standard"
      zone = local.zone
    }
    "fgt2-logdisk" = {
      name = "fgt2-logdisk-${random_string.string.result}"
      size = 30
      type = "pd-standard"
      zone = local.zone2
    }
  }

  #######################
  # Compute instances
  #######################

  compute_instances = {
    fgt1_instance = {
      name         = "${local.prefix}-fgt1-${random_string.string.result}"
      zone         = local.zone
      machine_type = local.fortigate_machine_type

      can_ip_forward = "true"
      tags           = ["fgt"]

      boot_disk_initialize_params_image = local.fortigate_vm_image

      attached_disk = [{
        source = google_compute_disk.compute_disk["fgt1-logdisk"].name
      }]

      network_interface = [{
        network    = google_compute_network.compute_network["untrust-vpc"].name
        subnetwork = google_compute_subnetwork.compute_subnetwork["untrust-subnet-1"].name
        network_ip = google_compute_address.compute_address["fgt1-untrust-ip"].address
        access_config = [{
          nat_ip = google_compute_address.compute_address["fgt1-static-ip"].address
        }]
        },
        {
          network       = google_compute_network.compute_network["trust-vpc"].name
          subnetwork    = google_compute_subnetwork.compute_subnetwork["trust-subnet-1"].name
          network_ip    = google_compute_address.compute_address["fgt1-trust-ip"].address
          access_config = []
      }]

      metadata = {
        user-data = data.template_file.template_file["fgt1-template"].rendered
      }
      service_account_scopes    = ["cloud-platform"]
      allow_stopping_for_update = true
    }

    fgt2_instance = {
      name         = "${local.prefix}-fgt2-${random_string.string.result}"
      zone         = local.zone2
      machine_type = local.fortigate_machine_type

      can_ip_forward = "true"
      tags           = ["fgt"]

      boot_disk_initialize_params_image = local.fortigate_vm_image

      attached_disk = [{
        source = google_compute_disk.compute_disk["fgt2-logdisk"].name
      }]

      network_interface = [{
        network    = google_compute_network.compute_network["untrust-vpc"].name
        subnetwork = google_compute_subnetwork.compute_subnetwork["untrust-subnet-1"].name
        network_ip = google_compute_address.compute_address["fgt2-untrust-ip"].address
        access_config = [{
          nat_ip = google_compute_address.compute_address["fgt2-static-ip"].address
        }]
        },
        {
          network       = google_compute_network.compute_network["trust-vpc"].name
          subnetwork    = google_compute_subnetwork.compute_subnetwork["trust-subnet-1"].name
          network_ip    = google_compute_address.compute_address["fgt2-trust-ip"].address
          access_config = []
      }]

      metadata = {
        user-data = data.template_file.template_file["fgt2-template"].rendered
      }
      service_account_scopes    = ["cloud-platform"]
      allow_stopping_for_update = true
    }
  }

  #######################
  # Template Files
  #######################

  template_files = {
    "fgt1-template" = {
      fgt_name         = "fgt1"
      template_file    = "fgt.conf"
      admin_port       = var.admin_port
      fgt_password     = var.fgt_password
      healthcheck_port = var.healthcheck_port
      license_type     = var.license_type
      license_token    = local.flex_tokens[0] != "" ? local.flex_tokens[0] : null
      license_file     = local.fortigate_license_files["fgt1_instance"].name != null ? file(local.fortigate_license_files["fgt1_instance"].name) : null
      port1-ip         = google_compute_address.compute_address["fgt1-untrust-ip"].address
      port2-ip         = google_compute_address.compute_address["fgt1-trust-ip"].address
      elb_ip           = google_compute_address.compute_address["elb-static-ip"].address
      ilb_ip           = google_compute_address.compute_address["ilb-ip"].address
      ext_gw           = google_compute_subnetwork.compute_subnetwork["untrust-subnet-1"].gateway_address
      int_gw           = google_compute_subnetwork.compute_subnetwork["trust-subnet-1"].gateway_address
      fgsp             = local.fgsp
      ha_index         = "1"
      peerip           = google_compute_address.compute_address["fgt2-trust-ip"].address
    }
    "fgt2-template" = {
      fgt_name         = "fgt2"
      template_file    = "fgt.conf"
      admin_port       = var.admin_port
      fgt_password     = var.fgt_password
      healthcheck_port = var.healthcheck_port
      license_type     = var.license_type
      license_token    = local.flex_tokens[1] != "" ? local.flex_tokens[1] : null
      license_file     = local.fortigate_license_files["fgt2_instance"].name != null ? file(local.fortigate_license_files["fgt2_instance"].name) : null
      port1-ip         = google_compute_address.compute_address["fgt2-untrust-ip"].address
      port2-ip         = google_compute_address.compute_address["fgt2-trust-ip"].address
      elb_ip           = google_compute_address.compute_address["elb-static-ip"].address
      ilb_ip           = google_compute_address.compute_address["ilb-ip"].address
      ext_gw           = google_compute_subnetwork.compute_subnetwork["untrust-subnet-1"].gateway_address
      int_gw           = google_compute_subnetwork.compute_subnetwork["trust-subnet-1"].gateway_address
      fgsp             = local.fgsp
      ha_index         = "2"
      peerip           = google_compute_address.compute_address["fgt1-trust-ip"].address
    }
  }

  #######################
  # load balancers info
  #######################

  #instance groups

  umigs = {
    "fgt1-umig" = {
      name      = "${local.prefix}-fgt1-umig-${random_string.string.result}"
      zone      = local.zone
      instances = [google_compute_instance.compute_instance["fgt1_instance"].self_link]
    }
    "fgt2-umig" = {
      name      = "${local.prefix}-fgt2-umig-${random_string.string.result}"
      zone      = local.zone2
      instances = [google_compute_instance.compute_instance["fgt2_instance"].self_link]
    }
  }

  # back end sets
  ibess = {
    "ilb_bes1" = {
      name    = "${local.prefix}-ilb-bes1-${random_string.string.result}"
      region  = local.region
      network = google_compute_network.compute_network["trust-vpc"].self_link
      group1  = google_compute_instance_group.fgt-umigs["fgt1-umig"].self_link
      group2  = google_compute_instance_group.fgt-umigs["fgt2-umig"].self_link
    }
  }
  ebess = {
    "elb_bes1" = {
      name                  = "${local.prefix}-elb-bes1-${random_string.string.result}"
      region                = local.region
      load_balancing_scheme = "EXTERNAL"
      group1                = google_compute_instance_group.fgt-umigs["fgt1-umig"].self_link
      group2                = google_compute_instance_group.fgt-umigs["fgt2-umig"].self_link
    }
  }

  # forwarding rules

  ifwd_rules = {
    "ilb_fwd_1" = {
      name                  = "${local.prefix}-ilb-fwd-1-${random_string.string.result}"
      region                = local.region
      network               = google_compute_network.compute_network["trust-vpc"].self_link
      subnetwork            = google_compute_subnetwork.compute_subnetwork["trust-subnet-1"].name
      ip_address            = google_compute_address.compute_address["ilb-ip"].address
      all_ports             = true
      load_balancing_scheme = "INTERNAL"
      backend_service       = google_compute_region_backend_service.ibes["ilb_bes1"].self_link
      allow_global_access   = true
    }
  }
  efwd_rules = {
    "elb_fwd_1" = {
      name                  = "${local.prefix}-elb-fwd-1-${random_string.string.result}"
      region                = local.region
      network               = null
      subnetwork            = null
      ip_address            = google_compute_address.compute_address["elb-static-ip"].address
      all_ports             = true
      load_balancing_scheme = "EXTERNAL"
      backend_service       = google_compute_region_backend_service.ebes["elb_bes1"].self_link
    }

  }
}




