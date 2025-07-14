# Changelog

## v1.5.1
* Add support for using a pre-created AWS IAM instance profile with the `aws_cloud_cluster_ec2_instance_profile_precreated` variable. This allows organizations with strict IAM policies to create the instance profile separately and reference it in the module.
* Add comprehensive IAM policy documentation including:
  * Required IAM permissions for the module in `docs/iam_policy.json`
  * Instance profile policy links to official Rubrik documentation
* Update quick-start documentation with security considerations and guidance for using pre-created instance profiles.
* Add `name` tag to S3 bucket resources for better resource identification.
* Update AMI filter example in documentation from `rubrik-mp-cc-7*` to `rubrik-mp-cc-8*`.

## v1.5.0
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

## v1.4.1
* Remove redundant empty provider statement
* Reduce non-data disk throughput when using split disks to 125.
