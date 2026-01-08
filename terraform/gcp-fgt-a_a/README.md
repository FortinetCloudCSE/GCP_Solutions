# GCP Active/Active dual zone FortiGate POC

## How do you run these?

1. Log into GCP console and open a cloud shell.
1. use `git clone https://github.com/fortidg/gcp-fgt-a_a.git` to clone this repo.
1. Open `terraform.tfvars.example`Change the name to 'terraform.tfvars' update the required variables (project, region, zone zone2, prefix, fortigate_vm_image, fortigate_machine_type)   
1. Run `terraform get`.
1. Run `terraform init`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.

### Licensing

There are three options for licensing the FortiGate VMs:

"flex" (default) - Set license_type to "flex" and add two unused FortiFlex tokens to the "flex_tokens" variable.  Ensure you are using the BYOL FortiGate image.  For Example:

```sh
flex_tokens = ["C5095E394QAZ3E640112", "DC65640C2QAZDD9CBC76"]
```

"byol" - Set license_type to "byol" and copy two valid fortigate licenses into the local directory.  Ensure you are using the BYOL FortiGate image. Update terraform.tfvars with the names of the licenses.  For example:

```sh
fortigate_license_files = {
  fgt1_instance    = { name = license1.lic }
  fgt2_instance = { name = license2.lic }
}
```

"payg" - Set license_type to "payg" and ensure that you are using the PAYG FortiGate Image  

If you wish to deploy FortGates in only one zone, you can use the same value for "zone" and "zone2".

FortiGates can be managed by putting `https://<fortigate-public-ip>:8443` into the url bar of your favorite browser. These IP addresses will be part of the Terraform outputs upon using apply.


### FGSP Note

By default, FGSP is disabled.  If you want to enable FGSP of this change the value of the **fgsp** variable to "true" in the terraform.tfvars file.

https://docs.fortinet.com/document/fortigate/7.6.2/administration-guide/668583/fgsp