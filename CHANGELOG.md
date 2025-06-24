# Changelog

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
