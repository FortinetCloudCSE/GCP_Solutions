---
title: "FortiGate Network Security Integration"
linkTitle: "FortiGate NSI"
weight: 9
---

![gcp-nsi](drawing.png)

## Solution Description

This solution uses Google Cloud Network Security Integration (NSI) to steer traffic from workload VPCs to FortiGate VMs for inspection. Terraform builds the FortiGate inspection infrastructure. A separate `setup-nsi.sh` step creates the NSI resources and associates them with the VPCs whose traffic you want to inspect.

The [Terraform configuration and full README](https://github.com/FortinetCloudCSE/GCP_Solutions/tree/main/terraform/gcp-nsi-umig) are in `terraform/gcp-nsi-umig`.

## How Traffic Reaches the FortiGates

1. A global network firewall policy on each associated workload VPC applies an NSI security profile group to ingress and egress traffic.
2. The security profile group references an intercept endpoint group and deployment group.
3. A deployment in each configured zone points to a forwarding rule for an internal UDP load balancer on port 6081. Intercepted traffic reaches the FortiGates using Geneve encapsulation.
4. The load balancer sends traffic to healthy FortiGate backends. Its regional backend service uses client IP session affinity and a health check on port 8080.

Each configured zone has one FortiGate VM in an **unmanaged instance group**. The default `zones` list has three zones. The FortiGates have an inspection interface in the inspection VPC and a management interface with an external IP in the management VPC. Cloud NAT provides internet egress for the inspection interface.

## Resources Deployed

| Component | Purpose |
| --- | --- |
| Inspection VPC and subnet | Carries the FortiGate data interfaces; the default subnet is `10.50.160.0/24`. |
| Management VPC and subnet | Carries the management interfaces; the default subnet is `10.50.180.0/24`. |
| FortiGate VMs and unmanaged instance groups | One VM and one group per zone, with no autoscaling configured. |
| Internal UDP load balancer | Regional backend service, health check, and a reserved frontend IP and forwarding rule for each zone. |
| Cloud Router and Cloud NAT | Internet egress from the inspection VPC for FortiGate services and updates. |
| Optional demo workload | Two peered web VPCs (`10.12.0.0/24` and `10.13.0.0/24`) with Debian web servers running Apache and iperf3. |

Terraform enables the Compute Engine, Network Security, and Cloud Resource Manager APIs. After Terraform completes, `setup-nsi.sh` creates the intercept deployment group, zone deployments, endpoint group, custom intercept security profile, security profile group, and global network firewall policy. It then associates the endpoint group and policy with the demo VPCs and any VPCs named in `CONSUMER_NETWORKS`.

## Deploy the Sample

You need a Google Cloud project with billing, an organization ID, permissions to create resources in the project and organization, Terraform 1.1 or later, Google Cloud CLI (`gcloud`), and `jq`. Authenticate `gcloud` and Terraform for the target project before deploying.

```sh
git clone https://github.com/FortinetCloudCSE/GCP_Solutions.git
cd GCP_Solutions/terraform/gcp-nsi-umig
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your `project_id`, `organization_id`, deployment region and zones, and a strong `admin_password`. Check the FortiGate image and license settings. The example selects the latest `fortigate-76-payg` image family; `fortigate_vm_image` can pin a specific image. The default configuration deploys three FortiGates and the demo workload.

```sh
terraform init
terraform plan
terraform apply
PROJECT_ID=your-gcp-project-id ORGANIZATION_ID=123456789012 ./setup-nsi.sh
```

`terraform apply` alone does not finish the NSI setup. Run the script from the Terraform directory so it can read the Terraform outputs. The FortiGate management addresses are available in the `fortigate_instances` output. Open `https://<management_ext_ip>:8443` and sign in as `admin` with the configured password.

### Inspect Your Own VPCs

Set `deploy_web_servers = false` in `terraform.tfvars` to omit the demo VPCs and servers. Supply workload VPC names from the same project when running the setup script:

```sh
CONSUMER_NETWORKS="prod-vpc,staging-vpc" PROJECT_ID=your-gcp-project-id ORGANIZATION_ID=123456789012 ./setup-nsi.sh
```

You can also use `CONSUMER_NETWORKS` alongside the demo VPCs. The script checks that each network exists and rejects the FortiGate inspection and management VPCs. Existing associations are skipped on a rerun.

**Review the policy before associating a production VPC.** The sample firewall policy applies its security profile group to all ingress and egress traffic (`0.0.0.0/0`) in every associated VPC. The Terraform sample also creates permissive VPC firewall rules, including management ingress. Restrict these rules for your environment. A VPC that already has a global network firewall policy cannot be associated with the sample policy by the setup script.

## Cleanup

Remove the NSI associations and resources before destroying the Terraform infrastructure. Pass the same `CONSUMER_NETWORKS` list used during setup:

```sh
CONSUMER_NETWORKS="prod-vpc,staging-vpc" PROJECT_ID=your-gcp-project-id ORGANIZATION_ID=123456789012 ./cleanup-nsi.sh
terraform destroy
```

Omit `CONSUMER_NETWORKS` if you did not use it. The cleanup script stops if it finds associations it cannot account for; include those networks before rerunning it.
