data "template_file" "template_file" {
  for_each = local.template_files

  template = file("${path.module}/templates/${each.value.template_file}")
  vars = {
    fgt_name         = each.value.fgt_name
    admin_port       = var.admin_port
    fgt_password     = var.fgt_password
    healthcheck_port = var.healthcheck_port
    license_type     = each.value.license_type
    license_file     = each.value.license_file
    license_token    = each.value.license_token
    port1-ip         = each.value.port1-ip
    port2-ip         = each.value.port2-ip
    elb_ip           = each.value.elb_ip
    ilb_ip           = each.value.ilb_ip
    ext_gw           = each.value.ext_gw
    int_gw           = each.value.int_gw
    fgsp             = each.value.fgsp
    ha_index         = each.value.ha_index
    peerip           = each.value.peerip
  }
}