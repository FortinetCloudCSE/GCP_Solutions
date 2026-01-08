variable "project" {}
variable "region" {}
variable "zone" {}
variable "zone2" {}

variable "prefix" {}

# FortiGates
variable "fortigate_machine_type" {}
variable "fortigate_vm_image" {}

variable "fgt_username" {
  type        = string
  default     = ""
  description = "FortiGate Username"
}
variable "fgt_password" {
  type        = string
  default     = ""
  description = "FortiGate Password"
}
variable "admin_port" {}

# debug
variable "enable_output" {
  type        = bool
  default     = true
  description = "Debug"
}

variable "healthcheck_port" {
  type        = number
  default     = 8008
  description = "Port used for LB health checks"
}

variable "flex_tokens" {
  type        = list(string)
  default     = ["", ""]
  description = "List of FortiFlex tokens to be applied during bootstrapping"
}

variable "license_type" {
  type        = string
  default     = "flex"
  description = "License type: flex, payg or byol"
}

variable "fortigate_license_files" {}

variable "fgsp" {
  type        = string
  default     = "false"
  description = "FortiGate FGSP mode: false"
  }

