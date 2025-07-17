# Terraform Module - AWS Cloud Cluster Deployment
This module deploys a new Rubrik Cloud Cluster Elastic Storage (CCES) in AWS.

## Usage
```hcl
# Configure the AWS Provider
provider "aws" {
  region = "us-west-1"
}

module "rubrik_aws_cloud_cluster" {
  source  = "rubrikinc/rubrik-cloud-cluster-elastic-storage/aws"

  aws_subnet_id     = "subnet-1234567890abcdefg"
  aws_ami_filter    = ["rubrik-mp-cc-7*"]
  cluster_name      = "rubrik-cloud-cluster"
  admin_email       = "build@rubrik.com"
  admin_password    = "RubrikGoForward"
  dns_search_domain = ["rubrikdemo.com"]
  dns_name_servers  = ["192.168.100.5","192.168.100.6"]
  ntp_server1_name  = "8.8.8.8"
  ntp_server2_name  = "8.8.4.4"
}
```

## Changelog

### v1.5.1
* Add support for using a pre-created AWS IAM instance profile with the `aws_cloud_cluster_ec2_instance_profile_precreated` variable. This allows organizations with strict IAM policies to create the instance profile separately and reference it in the module.
* Add comprehensive IAM policy documentation including:
  * Required IAM permissions for the module in `docs/iam_policy.json`
  * Instance profile policy links to official Rubrik documentation
* Update quick-start documentation with security considerations and guidance for using pre-created instance profiles.
* Add `name` tag to S3 bucket resources for better resource identification.
* Update AMI filter example in documentation from `rubrik-mp-cc-7*` to `rubrik-mp-cc-8*`.
* Remove legacy provider region declaration
* Remove `aws_region` variable and move to provider declaration

### v1.5.0
* Change the default value of the `admin_password` module input variable to `RubrikGoForward`. The old default value
  was too short to be accepted by CDM.
* Support specifying additional managed policies for the Cloud Cluster ES IAM role using the
  `aws_cloud_cluster_iam_managed_policies` module input variable.
* Support specifying an IAM role permission boundary for the Cloud Cluster ES IAM role using the
  `aws_cloud_cluster_iam_permission_boundary` module input variable.
* Deprecate the `enableImmutability` module input variable. Use the `enable_immutability` variable instead.
* Update the [polaris](https://registry.terraform.io/providers/rubrikinc/polaris/latest) Terraform provider to version
  `~>1.1.1`.
* Use the new `cluster_node_ip_address` field in the `polaris_cdm_boostram_cces_aws` resource to always connect to the
  first node. This prevents the provider from trying to connect to a node that is not yet bootstrapped.

### v1.4.1
* Remove redundant empty provider statement
* Reduce non-data disk throughput when using split disks to 125.

## Upgrading

### v1.5.0 to v1.5.1
1. Change the version of the module from `1.5.0` to `1.5.1`.
2. Remove the `aws_region` variable from the module and move the `region` declaration to the `provider "aws"` block.
```
provider "aws" {
  region = "us-west-1"
}
```
Note: the following error will occur during plan if not performed:
```log
Error: Unsupported argument
│ 
│   on main.tf line X, in module "rubrik_aws_cloud_cluster":
│    X:   aws_region = "us-west-1"
│ 
│ An argument named "aws_region" is not expected here.
```
3. Run `terraform init -upgrade`. The `-upgrade` command line option is required since the updated module requires a new
   version of the RSC (polaris) Terraform provider.
4. Run `terraform plan` and check the output carefully. The following output is expected:
```log
# module.iam_role will be moved to module.iam_role["true"]
# (due to existing moved block)

Plan: 0 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  ~ secrets_manager_get_ssh_key_command = "aws secretsmanager get-secret-value --region us-west-1 ..." -> "aws secretsmanager get-secret-value --region us-west-1 ..."
```
   There should be no resources replaced or removed.
4. Run `terraform apply`.

### v1.4.1 to v1.5.0
1. Change the version of the module from `1.4.1` to `1.5.0`.
2. Run `terraform init -upgrade`. The `-upgrade` command line option is required since the updated module requires a new
   version of the RSC (polaris) Terraform provider.
3. Run `terraform plan` and check the output carefully, only the `polaris_cdm_bootstrap_cces_aws` resource should have
   a diff and be updated in-place:
   ```text
   # module.rubrik_cluster.polaris_cdm_bootstrap_cces_aws.bootstrap_cces_aws will be updated in-place
   ~ resource "polaris_cdm_bootstrap_cces_aws" "bootstrap_cces_aws" {
       + cluster_node_ip_address = "<ip-address-of-first-node>"
         id                      = "<cluster-name>"
         # (15 unchanged attributes hidden)
     }
   ```
   There should be no resources replaced or removed.
4. Run `terraform apply`.

## Troubleshooting

### Error: OptInRequired
The Rubik Cloud Cluster product in the AWS Marketplace must be subscribed to. Otherwise, an error like this will be
displayed:
> Error: creating EC2 Instance: OptInRequired: In order to use this AWS Marketplace product you need to accept terms
> and subscribe. To do so please visit https://aws.amazon.com/marketplace/pp?sku=<sku-number>

If this occurs, open the specific link from the error, while logged into the AWS account where the Cloud Cluster will be
deployed. Follow the instructions for subscribing to the product.

## How You Can Help
We welcome contributions from the community. From updating the documentation to adding more functionality, all ideas are
welcome. Thank you in advance for all of your issues, pull requests, and comments!
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Contributing Guide](CONTRIBUTING.md)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |
| <a name="requirement_polaris"></a> [polaris](#requirement\_polaris) | ~>1.1.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.0.0 |
| <a name="provider_polaris"></a> [polaris](#provider\_polaris) | 1.1.1 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.13.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_key_pair"></a> [aws\_key\_pair](#module\_aws\_key\_pair) | terraform-aws-modules/key-pair/aws | ~> 2.0.0 |
| <a name="module_cluster_nodes"></a> [cluster\_nodes](#module\_cluster\_nodes) | ./modules/rubrik_aws_instances | n/a |
| <a name="module_iam_role"></a> [iam\_role](#module\_iam\_role) | ./modules/iam_role | n/a |
| <a name="module_rubrik_hosts_sg"></a> [rubrik\_hosts\_sg](#module\_rubrik\_hosts\_sg) | terraform-aws-modules/security-group/aws | n/a |
| <a name="module_rubrik_hosts_sg_rules"></a> [rubrik\_hosts\_sg\_rules](#module\_rubrik\_hosts\_sg\_rules) | ./modules/rubrik_hosts_sg | n/a |
| <a name="module_rubrik_nodes_sg"></a> [rubrik\_nodes\_sg](#module\_rubrik\_nodes\_sg) | terraform-aws-modules/security-group/aws | n/a |
| <a name="module_rubrik_nodes_sg_rules"></a> [rubrik\_nodes\_sg\_rules](#module\_rubrik\_nodes\_sg\_rules) | ./modules/rubrik_nodes_sg | n/a |
| <a name="module_s3_vpc_endpoint"></a> [s3\_vpc\_endpoint](#module\_s3\_vpc\_endpoint) | ./modules/s3_vpc_endpoint | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.cces-s3-bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.cces-s3-bucket-public-access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.cces-s3-bucket-encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.cces-s3-bucket-versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_secretsmanager_secret.cces-private-key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.cces-private-key-value](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [polaris_cdm_bootstrap_cces_aws.bootstrap_cces_aws](https://registry.terraform.io/providers/rubrikinc/polaris/latest/docs/resources/cdm_bootstrap_cces_aws) | resource |
| [polaris_cdm_registration.cces_aws_registration](https://registry.terraform.io/providers/rubrikinc/polaris/latest/docs/resources/cdm_registration) | resource |
| [time_sleep.wait_for_nodes_to_boot](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [tls_private_key.cc-key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_ami.cces_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami_ids.rubrik_cloud_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami_ids) | data source |
| [aws_subnet.rubrik_cloud_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.rubrik_cloud_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_email"></a> [admin\_email](#input\_admin\_email) | The Rubrik Cloud Cluster sends messages for the admin account to this email address. | `string` | n/a | yes |
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Password for the Rubrik Cloud Cluster admin account. | `string` | `"RubrikGoForward"` | no |
| <a name="input_aws_ami_filter"></a> [aws\_ami\_filter](#input\_aws\_ami\_filter) | Cloud Cluster AWS AMI name pattern(s) to search for. Use 'rubrik-mp-cc-<X>*' without the single quotes. Where <X> is the major version of CDM. Ex. 'rubrik-mp-cc-7*' | `set(string)` | n/a | yes |
| <a name="input_aws_ami_owners"></a> [aws\_ami\_owners](#input\_aws\_ami\_owners) | AWS marketplace account(s) that owns the Rubrik Cloud Cluster AMIs. Use use 679593333241 for AWS Commercial and 345084742485 for AWS GovCloud. | `set(string)` | <pre>[<br/>  "679593333241"<br/>]</pre> | no |
| <a name="input_aws_cloud_cluster_ec2_instance_profile_name"></a> [aws\_cloud\_cluster\_ec2\_instance\_profile\_name](#input\_aws\_cloud\_cluster\_ec2\_instance\_profile\_name) | AWS EC2 Instance Profile name that links the IAM Role to Cloud Cluster ES. If blank a name will be auto generated. | `string` | `""` | no |
| <a name="input_aws_cloud_cluster_iam_managed_policies"></a> [aws\_cloud\_cluster\_iam\_managed\_policies](#input\_aws\_cloud\_cluster\_iam\_managed\_policies) | Set of IAM managed policy ARNs to attach to the Cloud Cluster ES IAM role. | `set(string)` | `null` | no |
| <a name="input_aws_cloud_cluster_iam_permission_boundary"></a> [aws\_cloud\_cluster\_iam\_permission\_boundary](#input\_aws\_cloud\_cluster\_iam\_permission\_boundary) | ARN of the policy that is used to set the permissions boundary for the Cloud Cluster ES IAM role. | `string` | `null` | no |
| <a name="input_aws_cloud_cluster_iam_role_name"></a> [aws\_cloud\_cluster\_iam\_role\_name](#input\_aws\_cloud\_cluster\_iam\_role\_name) | AWS IAM Role name for Cloud Cluster ES. If blank a name will be auto generated. | `string` | `""` | no |
| <a name="input_aws_cloud_cluster_iam_role_policy_name"></a> [aws\_cloud\_cluster\_iam\_role\_policy\_name](#input\_aws\_cloud\_cluster\_iam\_role\_policy\_name) | AWS IAM Role policy name for Cloud Cluster ES. If blank a name will be auto generated. | `string` | `""` | no |
| <a name="input_aws_cloud_cluster_nodes_sg_ids"></a> [aws\_cloud\_cluster\_nodes\_sg\_ids](#input\_aws\_cloud\_cluster\_nodes\_sg\_ids) | Additional security groups to add to Rubrik cluster nodes. | `list(string)` | `[]` | no |
| <a name="input_aws_disable_api_termination"></a> [aws\_disable\_api\_termination](#input\_aws\_disable\_api\_termination) | If true, enables EC2 Instance Termination Protection on the Rubrik Cloud Cluster nodes. | `bool` | `true` | no |
| <a name="input_aws_image_id"></a> [aws\_image\_id](#input\_aws\_image\_id) | AWS Image ID to deploy. Set to 'latest' or leave blank to deploy the latest version from the marketplace. | `string` | `"latest"` | no |
| <a name="input_aws_instance_imdsv2"></a> [aws\_instance\_imdsv2](#input\_aws\_instance\_imdsv2) | Enable support for IMDSv2 instances. Only supported with CCES v8.1.3 or CCES v9.0 and higher. | `bool` | `false` | no |
| <a name="input_aws_instance_type"></a> [aws\_instance\_type](#input\_aws\_instance\_type) | The type of instance to use as Rubrik Cloud Cluster nodes. CC-ES requires m5.4xlarge. | `string` | `"m5.4xlarge"` | no |
| <a name="input_aws_key_pair_name"></a> [aws\_key\_pair\_name](#input\_aws\_key\_pair\_name) | Name for the AWS SSH Key-Pair being created or the existing AWS SSH Key-Pair being used. | `string` | `""` | no |
| <a name="input_aws_subnet_id"></a> [aws\_subnet\_id](#input\_aws\_subnet\_id) | The VPC Subnet ID to launch Rubrik Cloud Cluster in. | `string` | n/a | yes |
| <a name="input_aws_tags"></a> [aws\_tags](#input\_aws\_tags) | Tags to add to the AWS resources that this Terraform script creates, including the Rubrik cluster nodes. | `map(string)` | `{}` | no |
| <a name="input_aws_vpc_cloud_cluster_hosts_sg_name"></a> [aws\_vpc\_cloud\_cluster\_hosts\_sg\_name](#input\_aws\_vpc\_cloud\_cluster\_hosts\_sg\_name) | The name of the security group to create for Rubrik Cloud Cluster to communicate with EC2 instances. | `string` | `"Rubrik Cloud Cluster Hosts"` | no |
| <a name="input_aws_vpc_cloud_cluster_nodes_sg_name"></a> [aws\_vpc\_cloud\_cluster\_nodes\_sg\_name](#input\_aws\_vpc\_cloud\_cluster\_nodes\_sg\_name) | The name of the security group to create for Rubrik Cloud Cluster to use. | `string` | `"Rubrik Cloud Cluster Nodes"` | no |
| <a name="input_cloud_cluster_nodes_admin_cidr"></a> [cloud\_cluster\_nodes\_admin\_cidr](#input\_cloud\_cluster\_nodes\_admin\_cidr) | The CIDR range for the systems used to administer the Cloud Cluster via SSH and HTTPS. | `string` | `"0.0.0.0/0"` | no |
| <a name="input_cluster_disk_count"></a> [cluster\_disk\_count](#input\_cluster\_disk\_count) | The number of disks for each node in the cluster. Set to 1 to use with S3 storage for Cloud Cluster ES. | `number` | `1` | no |
| <a name="input_cluster_disk_size"></a> [cluster\_disk\_size](#input\_cluster\_disk\_size) | The size (in GB) of each data disk on each node. Cloud Cluster ES only requires 1 512 GB disk per node. | `number` | `512` | no |
| <a name="input_cluster_disk_type"></a> [cluster\_disk\_type](#input\_cluster\_disk\_type) | Disk type for the data disk: gp2 or gp3. Note, gp3 is only supported from version 8.1.1 for Cloud Cluster ES. | `string` | `"gp3"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Unique name to assign to the Rubrik Cloud Cluster. This will also be used to populate the EC2 instance name tag. For example, rubrik-cloud-cluster-1, rubrik-cloud-cluster-2 etc. | `string` | `"rubrik-cloud-cluster"` | no |
| <a name="input_create_s3_vpc_endpoint"></a> [create\_s3\_vpc\_endpoint](#input\_create\_s3\_vpc\_endpoint) | Determines whether an S3 VPC endpoint is created. | `bool` | `true` | no |
| <a name="input_dns_name_servers"></a> [dns\_name\_servers](#input\_dns\_name\_servers) | List of the IPv4 addresses of the DNS servers. | `list(any)` | <pre>[<br/>  "169.254.169.253"<br/>]</pre> | no |
| <a name="input_dns_search_domain"></a> [dns\_search\_domain](#input\_dns\_search\_domain) | List of search domains that the DNS Service will use to resolve hostnames that are not fully qualified. | `list(any)` | `[]` | no |
| <a name="input_enableImmutability"></a> [enableImmutability](#input\_enableImmutability) | Deprecated: use enable\_immutability instead. | `bool` | `null` | no |
| <a name="input_enable_immutability"></a> [enable\_immutability](#input\_enable\_immutability) | Enables object lock and versioning on the S3 bucket. Sets the object lock flag during bootstrap. Not supported on CDM v8.0.1 and earlier. | `bool` | `null` | no |
| <a name="input_node_boot_wait"></a> [node\_boot\_wait](#input\_node\_boot\_wait) | Number of seconds to wait for CCES nodes to boot before attempting to bootstrap them. | `number` | `300` | no |
| <a name="input_ntp_server1_key"></a> [ntp\_server1\_key](#input\_ntp\_server1\_key) | Symmetric key material for NTP server #1. | `string` | `""` | no |
| <a name="input_ntp_server1_key_id"></a> [ntp\_server1\_key\_id](#input\_ntp\_server1\_key\_id) | The ID number of the symmetric key used with NTP server #1. (Typically this is 0) | `number` | `0` | no |
| <a name="input_ntp_server1_key_type"></a> [ntp\_server1\_key\_type](#input\_ntp\_server1\_key\_type) | Symmetric key type for NTP server #1. | `string` | `""` | no |
| <a name="input_ntp_server1_name"></a> [ntp\_server1\_name](#input\_ntp\_server1\_name) | The FQDN or IPv4 addresses of network time protocol (NTP) server #1. | `string` | `"8.8.8.8"` | no |
| <a name="input_ntp_server2_key"></a> [ntp\_server2\_key](#input\_ntp\_server2\_key) | Symmetric key material for NTP server #2. | `string` | `""` | no |
| <a name="input_ntp_server2_key_id"></a> [ntp\_server2\_key\_id](#input\_ntp\_server2\_key\_id) | The ID number of the symmetric key used with NTP server #2. (Typically this is 0) | `number` | `0` | no |
| <a name="input_ntp_server2_key_type"></a> [ntp\_server2\_key\_type](#input\_ntp\_server2\_key\_type) | Symmetric key type for NTP server #2. | `string` | `""` | no |
| <a name="input_ntp_server2_name"></a> [ntp\_server2\_name](#input\_ntp\_server2\_name) | The FQDN or IPv4 addresses of network time protocol (NTP) server #2. | `string` | `"8.8.4.4"` | no |
| <a name="input_number_of_nodes"></a> [number\_of\_nodes](#input\_number\_of\_nodes) | The total number of nodes in Rubrik Cloud Cluster. | `number` | `3` | no |
| <a name="input_private_key_recovery_window_in_days"></a> [private\_key\_recovery\_window\_in\_days](#input\_private\_key\_recovery\_window\_in\_days) | Recovery window in days to recover script generated ssh private key. | `number` | `30` | no |
| <a name="input_register_cluster_with_rsc"></a> [register\_cluster\_with\_rsc](#input\_register\_cluster\_with\_rsc) | Register the Rubrik Cloud Cluster with Rubrik Security Cloud. | `bool` | `false` | no |
| <a name="input_s3_bucket_force_destroy"></a> [s3\_bucket\_force\_destroy](#input\_s3\_bucket\_force\_destroy) | A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. | `bool` | `false` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Name of the S3 bucket to use with Cloud Cluster ES data storage. If blank a name will be auto generated. | `string` | `""` | no |
| <a name="input_s3_vpc_endpoint_route_table_ids"></a> [s3\_vpc\_endpoint\_route\_table\_ids](#input\_s3\_vpc\_endpoint\_route\_table\_ids) | Route table IDs if S3 VPC endpoint is created. | `list(string)` | `[]` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | The number of seconds to wait to establish a connection the Rubrik cluster before returning a timeout error. | `string` | `"4m"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_rubrik_cloud_cluster_ip_addresses"></a> [rubrik\_cloud\_cluster\_ip\_addresses](#output\_rubrik\_cloud\_cluster\_ip\_addresses) | n/a |
| <a name="output_rubrik_hosts_sg_id"></a> [rubrik\_hosts\_sg\_id](#output\_rubrik\_hosts\_sg\_id) | n/a |
| <a name="output_s3_bucket"></a> [s3\_bucket](#output\_s3\_bucket) | n/a |
| <a name="output_secrets_manager_get_ssh_key_command"></a> [secrets\_manager\_get\_ssh\_key\_command](#output\_secrets\_manager\_get\_ssh\_key\_command) | n/a |
| <a name="output_secrets_manager_private_key_name"></a> [secrets\_manager\_private\_key\_name](#output\_secrets\_manager\_private\_key\_name) | n/a |
<!-- END_TF_DOCS -->
