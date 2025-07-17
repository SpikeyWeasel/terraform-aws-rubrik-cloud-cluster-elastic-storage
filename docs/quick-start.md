# Quick Start: Rubrik AWS Cloud Cluster Elastic Storage Deployment Terraform Module

Completing the steps detailed below will require that Terraform is installed and in your environment path, that you are running the instance from a \*nix shell (bash, zsh, etc), and that your machine is allowed HTTPS access through the AWS Security Group, and any Network ACLs, into the instances provisioned.

## Security Considerations

To use this module you will need the AWS IAM permissions detailed in [Required IAM Permissions][module-iam-policy] - the latest permissions can be checked in the [Rubrik documentation](https://docs.rubrik.com/en-us/saas/saas/aws_req_perms_table_cc_es_deploying.html).

Note: When using immutable S3 buckets, the following IAM permissions may be required on the resource `arn:aws:s3:::<bucket_name>`:
```
  "s3:GetBucketObjectLockConfiguration",
  "s3:GetObjectLegalHold",
  "s3:GetObjectRetention",
  "s3:PutObjectLegalHold",
  "s3:PutObjectRetention"
```

In environments where IAM permissions need to be more tightly controlled, this module offers flexible deployment options to accommodate different security requirements. There are two approaches available:

- Supply a permissions boundary policy ARN using the `aws_cloud_cluster_iam_permission_boundary` variable that is applied to the IAM role created by this module.
- Alternatively request your Cloud Security team to create an AWS IAM instance profile with the JSON policy outlined in [instance-profile-policy](https://docs.rubrik.com/en-us/saas/common/aws_cloud_cluster_prerequisites.html) (Note: depending on you're KMS implementation, refer to the relevant JSON Policy). The instance policy examples require the `<bucket_name>` placeholder to be replaced with either the value supplied for `s3_bucket_name` or "`cluster_name`.bucket-do-not-delete".
The profile name is then passed to the module with the `aws_cloud_cluster_ec2_instance_profile_name` and with `set aws_cloud_cluster_ec2_instance_profile_precreated` set to `true`. This will eliminate the need for the module to require the IAM permissions listed.

> __NOTE__ The IAM policy required to run the module should be tailored to meet your individual least privilege policy requirements. However the instance profile policies should be used exactly as per the examples for the cluster to function correctly.

## Configuration

In your [Terraform configuration](https://learn.hashicorp.com/terraform/getting-started/build#configuration) (`main.tf`) populate the following and update the variables to your specific environment:

```hcl
# Configure the AWS Provider
provider "aws" {
  region = "us-west-1"
}

module "rubrik_aws_cloud_cluster_elastic_storage" {
  source  = "rubrikinc/rubrik-cloud-cluster-elastic-storage/aws"

  aws_subnet_id               = "subnet-1234567890abcdefg"
  aws_ami_filter              = ["rubrik-mp-cc-8*"]
  cluster_name                = "rubrik-cloud-cluster"
  admin_email                 = "build@rubrik.com"
  admin_password              = "RubrikGoForward"
  dns_search_domain           = ["rubrikdemo.com"]
  dns_name_servers            = ["192.168.100.5","192.168.100.6"]
  ntp_server1_name            = "8.8.8.8"
  ntp_server2_name            = "8.8.4.4"
}
```

You may also add additional variables, such as `aws_instance_type`, to overwrite the default values.

**Note:** This module requires you to configure the AWS provider in your calling configuration. The provider should be configured with the appropriate region and credentials for your AWS environment.

## Inputs

The following are the variables accepted by the module.

### Instance/Node Settings

| Name                                            | Description                                                                                                              |  Type  |          Default           | Required |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | :----: | :------------------------: | :------: |
| aws_instance_imdsv2                             | Enable support for IMDSv2 instances. Only supported with CCES v8.1.3 or CCES v9.0 and higher.                            |  bool  |           false            |    no    |
| aws_instance_type                               | The type of instance to use as Rubrik Cloud Cluster nodes. CC-ES requires m5.4xlarge.                                    | string |         m5.4xlarge         |    no    |
| aws_disable_api_termination                     | If true, enables EC2 Instance Termination Protection on the Rubrik Cloud Cluster nodes.                                  |  bool  |            true            |    no    |
| aws_tags                                        | Tags to add to the resources that this Terraform script creates, including the Rubrik cluster nodes.                     |  map   |                            |    no    |
| number_of_nodes                                 | The total number of nodes in Rubrik Cloud Cluster.                                                                       |  int   |             3              |    no    |
| aws_ami_owners                                  | AWS marketplace account(s) that owns the Rubrik Cloud Cluster AMIs. Use [\"345084742485\"] for AWS GovCloud.             |  list  |      ["679593333241"]      |    no    |
| aws_ami_filter                                  | Cloud Cluster AWS AMI name pattern(s) to search for. Use [\"rubrik-mp-cc-[X]*\"]. Where [X] is the major version of CDM. |  list  |                            |   yes    |
| aws_image_id                                    | AWS Image ID to deploy. Set to 'latest' or leave blank to deploy the latest version as determined by `aws_ami_filter`.   | string |           latest           |    no    |
| aws_key_pair_name                               | Name for the AWS SSH Key-Pair being created or the existing AWS SSH Key-Pair being used.                                 | string |                            |    no    |
| private_key_recovery_window_in_days             | Recovery window in days to recover script generated ssh private key.                                                     | string |             30             |    no    |

*Note: When using the `aws_tags` variable, the "Name" tag is automatically used by this TF for those resources that support it.*

*Note: The `aws_ami_filter` and `aws_ami_owners` variables are only used when the `aws_image_id` variable is blank or set to `latest`*

*Note: When using the `aws_image_id` variable, see [Selecting a specific image](#selecting-a-specific-image) for details on finding images.*

*Note: When using the `aws_key_pair_name` variable, if a new AWS SSH Key-Pair is being created and no name is specified, a name will be automatically generated.*

<br>

### Network Settings

| Name                                            | Description                                                                                                              |  Type  |          Default           | Required |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | :----: | :------------------------: | :------: |
| create_cloud_cluster_nodes_sg                   | If true, creates a new Security Group for node to node traffic within the Rubrik cluster.                                |  bool  |            true            |    no    |
| aws_vpc_cloud_cluster_nodes_sg_name             | The name of the security group to create for Rubrik Cloud Cluster to use.                                                | string |    Rubrik Cloud Cluster    |    no    |
| cloud_cluster_nodes_admin_cidr                  | The CIDR range for the systems used to administer the Cloud Cluster via SSH and HTTPS.                                   | string |         0.0.0.0/0          |    no    |
| create_cloud_cluster_hosts_sg                   | If true, creates a new Security Group for node to host traffic from the Rubrik cluster.                                  | string |            true            |    no    |
| aws_vpc_cloud_cluster_hosts_sg_name             | The name of the security group to create for Rubrik Cloud Cluster to communicate with EC2 instances.                     | string | Rubrik Cloud Cluster Hosts |    no    |
| aws_cloud_cluster_nodes_sg_ids                  | Additional security groups to add to Rubrik cluster nodes.                                                               | string |                            |    no    |
| aws_subnet_id                                   | The VPC Subnet ID to launch Rubrik Cloud Cluster in.                                                                     | string |                            |   yes    |

### Cache Disk Storage Settings

| Name                                            | Description                                                                                             |  Type  |          Default           | Required |
| ----------------------------------------------- |---------------------------------------------------------------------------------------------------------| :----: | :------------------------: | :------: |
| cluster_disk_type                               | Disk type for the data disks (gp2).                                                                     | string |            gp2             |    no    |
| cluster_disk_size                               | The size (in GB) of each data disk on each node. Cloud Cluster ES only requires 1 512 GB disk per node. | string |            512             |    no    |
| cluster_disk_count                              | The number of disks for each node in the cluster. Set to 1 for Cloud Cluster ES.                        |  int   |             1              |    no    |

### Cloud Cluster ES Settings

| Name                                               | Description                                                                                                           |  Type  | Default | Required |
|----------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------| :----: |:-------:| :------: |
| aws_cloud_cluster_iam_role_name                    | AWS IAM Role name for Cloud Cluster ES. If blank a name will be auto generated. Required if create_iam_role is false. | string |         |    no    |
| aws_cloud_cluster_iam_role_policy_name             | AWS IAM Role policy name for Cloud Cluster ES if create_iam_role is true. If blank a name will be auto generated.     | string |         |    no    |
| aws_cloud_cluster_ec2_instance_profile_name        | AWS EC2 Instance Profile name that links the IAM Role to Cloud Cluster ES. If blank a name will be auto generated.    | string |         |    no    |
| aws_cloud_cluster_ec2_instance_profile_precreated  | Indicates whether the AWS EC2 Instance Profile name, if supplied, has already been created.                           | bool   |  false  |    no    |
| aws_cloud_cluster_iam_permission_boundary          | ARN of the IAM policy to be used as the permissions boundary for the Cloud Cluster ES IAM role                        | string |         |    no    |
| create_s3_bucket                                   | If true, create am S3 bucket for Cloud Cluster ES data storage.                                                       |  bool  |  true   |    no    |
| s3_bucket_name                                     | Name of the S3 bucket to use with Cloud Cluster ES data storage. If blank a name will be auto generated.              | string |         |    no    |
| s3_bucket_force_destroy                            | Indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error.            |  bool  |  false  |    no    |
| enable_immutability                                | Enable immutability on the S3 objects that CCES uses. Default value is true.                                          |  bool  |  true   |    no    |
| create_s3_vpc_endpoint                             | If true, create a VPC Endpoint and S3 Endpoint Service for Cloud Cluster ES.                                          |  bool  |  true   |    no    |
| s3_vpc_endpoint_route_table_ids                    | Route table IDs for VPC Endpoint and S3 Endpoint Service.                                                             |  list  |         |    no    |

### Bootstrap Settings

| Name                                            | Description                                                                                                              |  Type  |       Default       | Required |
| ----------------------------------------------- |--------------------------------------------------------------------------------------------------------------------------|:------:|:-------------------:|:--------:|
| cluster_name                                    | Unique name to assign to Rubrik Cloud Cluster. Also used for EC2 instance name tag. For example, rubrik-1, rubrik-2 etc. | string |                     |   yes    |
| admin_email                                     | The Rubrik Cloud Cluster sends messages for the admin account to this email address.                                     | string |                     |   yes    |
| admin_password                                  | Password for the Rubrik Cloud Cluster admin account.                                                                     | string |   RubrikGoForward   |    no    |
| dns_search_domain                               | List of search domains that the DNS Service will use to resolve hostnames that are not fully qualified.                  |  list  |                     |   yes    |
| dns_name_servers                                | List of the IPv4 addresses of the DNS servers.                                                                           |  list  | ["169.254.169.253"] |    no    |
| ntp_server1_name                                | The FQDN or IPv4 addresses of network time protocol (NTP) server #1.                                                     | string |       8.8.8.8       |   yes    |
| ntp_server1_key_id                              | The ID # of the key for NTP server #1. Typically is set to 0. (Required with `ntp_server1_key` & `ntp_server1_key_type`) |  int   |          0          |    no    |
| ntp_server1_key                                 | Symmetric key material for NTP server #1. (Required with `ntp_server1_key_id` and `ntp_server1_key_type`)                | string |                     |    no    |
| ntp_server1_key_type                            | Symmetric key type for NTP server #1. (Required with `ntp_server1_key` and `ntp_server1_key_id`)                         | string |                     |    no    |
| ntp_server2_name                                | The FQDN or IPv4 addresses of network time protocol (NTP) server #2.                                                     | string |       8.8.4.4       |   yes    |
| ntp_server2_key_id                              | The ID # of the key for NTP server #2. Typically is set to 1. (Required with `ntp_server1_key` & `ntp_server1_key_type`) |  int   |          1          |    no    |
| ntp_server2_key                                 | Symmetric key material for NTP server #2. (Required with `ntp_server1_key_id` and `ntp_server1_key_type`)                | string |                     |    no    |
| ntp_server2_key_type                            | Symmetric key type for NTP server #2. (Required with `ntp_server1_key` and `ntp_server1_key_id`)                         | string |                     |    no    |
| timeout                                         | The number of seconds to wait to establish a connection the Rubrik cluster before returning a timeout error.             |  int   |         60          |    no    |
| node_boot_wait                                  | Number of seconds to wait for CCES nodes to boot before attempting to bootstrap them.                                    |  int   |         300         |    no    |
| register_cluster_with_rsc                       | Register the Rubrik Cloud Cluster with Rubrik Security Cloud. Default value is false.                                    |  bool  |        false        |    no    |

## Running the Terraform Configuration

This section outlines what is required to run the configuration defined above.

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) v1.2.2 or greater
- [Rubrik RSC Provider for Terraform](https://github.com/rubrikinc/terraform-provider-polaris) - provides Terraform functions for Rubrik
  - Only required to run the sample Rubrik Bootstrap command
- The Rubik Cloud Cluster product in the AWS Marketplace must be subscribed to. Otherwise, an error like this will be displayed:
  > Error: creating EC2 Instance: OptInRequired: In order to use this AWS Marketplace product you need to accept terms and subscribe. To do so please visit `https://aws.amazon.com/marketplace/pp?sku=<sku_number>`

    If this occurs, open the specific link from the error, while logged into the AWS account where Cloud Cluster will be deployed. Follow the instructions for subscribing to the product.

### Initialize the Directory

The directory can be initialized for Terraform use by running the `terraform init` command:

```log
-> terraform init
Initializing modules...
Downloading registry.terraform.io/terraform-aws-modules/key-pair/aws 2.0.1 for aws_key_pair...
- aws_key_pair in .terraform/modules/aws_key_pair
- cluster_nodes in modules/rubrik_aws_instances
- iam_role in modules/iam_role
Downloading registry.terraform.io/terraform-aws-modules/security-group/aws 4.16.2 for rubrik_hosts_sg...
- rubrik_hosts_sg in .terraform/modules/rubrik_hosts_sg
- rubrik_hosts_sg_rules in modules/rubrik_hosts_sg
Downloading registry.terraform.io/terraform-aws-modules/security-group/aws 4.16.2 for rubrik_hosts_sg_rules.this...
- rubrik_hosts_sg_rules.this in .terraform/modules/rubrik_hosts_sg_rules.this
Downloading registry.terraform.io/terraform-aws-modules/security-group/aws 4.16.2 for rubrik_nodes_sg...
- rubrik_nodes_sg in .terraform/modules/rubrik_nodes_sg
- rubrik_nodes_sg_rules in modules/rubrik_nodes_sg
Downloading registry.terraform.io/terraform-aws-modules/security-group/aws 4.16.2 for rubrik_nodes_sg_rules.this...
- rubrik_nodes_sg_rules.this in .terraform/modules/rubrik_nodes_sg_rules.this
Downloading registry.terraform.io/terraform-aws-modules/s3-bucket/aws 3.6.0 for s3_bucket...
- s3_bucket in .terraform/modules/s3_bucket
- s3_vpc_endpoint in modules/s3_vpc_endpoint

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching ">= 3.29.0, >= 4.9.0, >= 4.21.0"...
- Finding latest version of rubrikinc/rubrik/rubrik...
- Finding latest version of hashicorp/local...
- Finding latest version of hashicorp/time...
- Finding hashicorp/tls versions matching ">= 3.4.0"...
- Installing hashicorp/time v0.9.1...
- Installed hashicorp/time v0.9.1 (signed by HashiCorp)
- Installing hashicorp/tls v4.0.4...
- Installed hashicorp/tls v4.0.4 (signed by HashiCorp)
- Installing hashicorp/aws v4.40.0...
- Installed hashicorp/aws v4.40.0 (signed by HashiCorp)
- Installing rubrikinc/rubrik/rubrik v2.1.0...
- Installed rubrikinc/rubrik/rubrik v2.1.0 (unauthenticated)
- Installing hashicorp/local v2.2.3...
- Installed hashicorp/local v2.2.3 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

### Gain Access to the Rubrik Cloud Cluster AMI

The Terraform script will automatically install the latest maintenance release of Rubrik Cloud Cluster major version (as defined by the `aws_ami_filter` variable) from the AWS Marketplace. If a different version of Cloud Cluster is required modify the filters in the `aws_image_id`, `aws_ami_owners` and/or `aws_ami_filter` variables.

### Planning

Run `terraform plan` to get information about what will happen when we apply the configuration; this will test that everything is set up correctly.

### Applying

We can now apply the configuration to create the cluster using the `terraform apply` command.

### Configuring the Cloud Cluster

If the example script for bootstrapping the Rubrik Cloud Cluster is not used, bootstrap the Rubrik Cloud Cluster as documented in the Rubrik Cloud Cluster guide.
The Cloud Cluster can now be configured through the Web UI; access to the interface will depend on the Security Group applied in the configuration above.

### Destroying

Once the Cloud Cluster is no longer required, it can be destroyed using the `terraform destroy` command, and entering `yes` when prompted. This will also destroy the attached EBS volumes.

## Selecting a specific image

To select a specific image to deploy replace the `aws_image_id` variable with the AMI ID of the Rubrik Marketplace Image to deploy. To find a list of the Rubrik Cloud Cluster images that are available in a specific region run the following `aws` cli command (requires that the AWS CLI be installed):

```bash
  aws ec2 describe-images \
    --filters 'Name=owner-id,Values=679593333241' 'Name=name,Values=rubrik-mp-cc-<X>*' \
     --query 'sort_by(Images, &CreationDate)[*].{"Create Date":CreationDate, "Image ID":ImageId, Version:Description}' \
    --region '<region>' \
    --output table
```

Where <X> is the major version of Rubrik CDM (ex. `rubrik-mp-cc-7*`)

Example:

```bash
aws ec2 describe-images \
     --filters 'Name=owner-id,Values=679593333241' 'Name=name,Values=rubrik-mp-cc-8*' \
     --query 'sort_by(Images, &CreationDate)[*].{"Create Date":CreationDate, "Image ID":ImageId, Version:Description}' \
      --region 'us-west-2' \
     --output table

-------------------------------------------------------------------------------------------
|                                     DescribeImages                                      |
+--------------------------+-------------------------+------------------------------------+
|        Create Date       |        Image ID         |              Version               |
+--------------------------+-------------------------+------------------------------------+
|  2023-08-01T03:51:42.000Z|  ami-067a772923ed7ae42  |  Rubrik OS rubrik-8-0-3-p7-22941   |
|  2023-08-01T03:51:43.000Z|  ami-0a923aa5a73b43b07  |  Rubrik OS rubrik-8-1-2-p2-24758   |
|  2023-08-17T17:20:00.000Z|  ami-0b682ec0d8be45f12  |  Rubrik OS rubrik-8-1-3-24772      |
|  2023-08-25T22:58:55.000Z|  ami-0b4257592e8411404  |  Rubrik OS rubrik-8-1-3-p1-24838   |
|  2023-08-31T20:22:17.000Z|  ami-01abb97252b6c4558  |  Rubrik OS rubrik-8-0-3-p9-22986   |
|  2023-09-23T00:01:38.000Z|  ami-09be5daf9a3cc64fc  |  Rubrik OS rubrik-8-0-3-p10-23002  |
|  2023-09-23T00:01:46.000Z|  ami-04d7caeafb447ed2e  |  Rubrik OS rubrik-8-1-3-p2-24912   |
|  2023-10-05T05:45:43.000Z|  ami-023dc23b2e51fdf43  |  Rubrik OS rubrik-8-0-3-p11-23020  |
|  2023-10-05T05:46:50.000Z|  ami-04e8e666d492d928e  |  Rubrik OS rubrik-8-1-3-p3-24955   |
|  2023-10-26T21:36:15.000Z|  ami-07c748ac94aa02ac5  |  Rubrik OS rubrik-8-1-3-p4-25026   |
|  2023-11-01T19:14:44.000Z|  ami-097d4b1ee571e3b90  |  Rubrik OS rubrik-8-0-3-p12-23046  |
|  2023-11-22T00:15:10.000Z|  ami-01c55f34d5012033f  |  Rubrik OS rubrik-8-0-3-p13-23073  |
|  2023-11-22T00:15:11.000Z|  ami-0b0d8c098a3515def  |  Rubrik OS rubrik-8-1-3-p5-25104   |
|  2023-12-16T00:31:38.000Z|  ami-0e308b84bcc743473  |  Rubrik OS rubrik-8-0-3-p14-23094  |
|  2023-12-21T19:54:33.000Z|  ami-0f1c616525ba03323  |  Rubrik OS rubrik-8-1-3-p6-25199   |
|  2024-01-12T00:36:30.000Z|  ami-02438d1336629d0dc  |  Rubrik OS rubrik-8-0-3-p15-23110  |
|  2024-02-02T02:05:34.000Z|  ami-0d60b767d6f011525  |  Rubrik OS rubrik-8-1-3-p7-25298   |
|  2024-03-05T08:50:35.000Z|  ami-0bcd805fbbcacd4b2  |  Rubrik OS rubrik-8-1-3-p8-25376   |
|  2024-03-29T15:18:16.000Z|  ami-0f305dc10a76b8553  |  Rubrik OS rubrik-8-1-3-p9-25413   |
|  2024-05-11T02:13:09.000Z|  ami-03c071f37547cd672  |  Rubrik OS rubrik-8-1-3-p10-25441  |
|  2024-05-23T18:20:53.000Z|  ami-0815e8be35e1a042f  |  Rubrik OS rubrik-8-1-3-p11-25483  |
|  2024-06-12T23:25:19.000Z|  ami-078d4359ebe4fdcb8  |  Rubrik OS rubrik-8-1-3-p12-25506  |
|  2024-07-03T05:32:07.000Z|  ami-0dbecd498404d7941  |  Rubrik OS rubrik-8-1-3-p13-25544  |
|  2024-07-26T23:07:26.000Z|  ami-06cba747bf460959a  |  Rubrik OS rubrik-8-1-3-p14-25570  |
|  2024-09-04T00:53:01.000Z|  ami-065ea2a074aff651c  |  Rubrik OS rubrik-8-1-3-p15-25607  |
|  2024-11-05T14:27:13.000Z|  ami-06e537a3af3d5f19a  |  Rubrik OS rubrik-8-1-3-p16-25670  |
|  2025-01-29T21:17:37.000Z|  ami-0803e67a19b1cd9d8  |  Rubrik OS rubrik-8-1-3-p17-25752  |
+--------------------------+-------------------------+------------------------------------+
```

For AWS Gov cloud change the `owner-id` to `345084742485`.

Example:

```bash
aws ec2 describe-images \
    --filters 'Name=owner-id,Values=345084742485' 'Name=name,Values=rubrik-mp-cc-8*' \
    --query 'sort_by(Images, &CreationDate)[*].{"Create Date":CreationDate, "Image ID":ImageId, Version:Description}' \
    --region 'us-gov-west-1' \
    --output table

-------------------------------------------------------------------------------------------
|                                     DescribeImages                                      |
+--------------------------+-------------------------+------------------------------------+
|        Create Date       |        Image ID         |              Version               |
+--------------------------+-------------------------+------------------------------------+
|  2023-08-01T03:51:42.000Z|  ami-067a772923ed7ae42  |  Rubrik OS rubrik-8-0-3-p7-22941   |
|  2023-08-01T03:51:43.000Z|  ami-0a923aa5a73b43b07  |  Rubrik OS rubrik-8-1-2-p2-24758   |
|  2023-08-17T17:20:00.000Z|  ami-0b682ec0d8be45f12  |  Rubrik OS rubrik-8-1-3-24772      |
|  2023-08-25T22:58:55.000Z|  ami-0b4257592e8411404  |  Rubrik OS rubrik-8-1-3-p1-24838   |
|  2023-08-31T20:22:17.000Z|  ami-01abb97252b6c4558  |  Rubrik OS rubrik-8-0-3-p9-22986   |
|  2023-09-23T00:01:38.000Z|  ami-09be5daf9a3cc64fc  |  Rubrik OS rubrik-8-0-3-p10-23002  |
|  2023-09-23T00:01:46.000Z|  ami-04d7caeafb447ed2e  |  Rubrik OS rubrik-8-1-3-p2-24912   |
|  2023-10-05T05:45:43.000Z|  ami-023dc23b2e51fdf43  |  Rubrik OS rubrik-8-0-3-p11-23020  |
|  2023-10-05T05:46:50.000Z|  ami-04e8e666d492d928e  |  Rubrik OS rubrik-8-1-3-p3-24955   |
|  2023-10-26T21:36:15.000Z|  ami-07c748ac94aa02ac5  |  Rubrik OS rubrik-8-1-3-p4-25026   |
|  2023-11-01T19:14:44.000Z|  ami-097d4b1ee571e3b90  |  Rubrik OS rubrik-8-0-3-p12-23046  |
|  2023-11-22T00:15:10.000Z|  ami-01c55f34d5012033f  |  Rubrik OS rubrik-8-0-3-p13-23073  |
|  2023-11-22T00:15:11.000Z|  ami-0b0d8c098a3515def  |  Rubrik OS rubrik-8-1-3-p5-25104   |
|  2023-12-16T00:31:38.000Z|  ami-0e308b84bcc743473  |  Rubrik OS rubrik-8-0-3-p14-23094  |
|  2023-12-21T19:54:33.000Z|  ami-0f1c616525ba03323  |  Rubrik OS rubrik-8-1-3-p6-25199   |
|  2024-01-12T00:36:30.000Z|  ami-02438d1336629d0dc  |  Rubrik OS rubrik-8-0-3-p15-23110  |
|  2024-02-02T02:05:34.000Z|  ami-0d60b767d6f011525  |  Rubrik OS rubrik-8-1-3-p7-25298   |
|  2024-03-05T08:50:35.000Z|  ami-0bcd805fbbcacd4b2  |  Rubrik OS rubrik-8-1-3-p8-25376   |
|  2024-03-29T15:18:16.000Z|  ami-0f305dc10a76b8553  |  Rubrik OS rubrik-8-1-3-p9-25413   |
|  2024-05-11T02:13:09.000Z|  ami-03c071f37547cd672  |  Rubrik OS rubrik-8-1-3-p10-25441  |
|  2024-05-23T18:20:53.000Z|  ami-0815e8be35e1a042f  |  Rubrik OS rubrik-8-1-3-p11-25483  |
|  2024-06-12T23:25:19.000Z|  ami-078d4359ebe4fdcb8  |  Rubrik OS rubrik-8-1-3-p12-25506  |
|  2024-07-03T05:32:07.000Z|  ami-0dbecd498404d7941  |  Rubrik OS rubrik-8-1-3-p13-25544  |
|  2024-07-26T23:07:26.000Z|  ami-06cba747bf460959a  |  Rubrik OS rubrik-8-1-3-p14-25570  |
|  2024-09-04T00:53:01.000Z|  ami-065ea2a074aff651c  |  Rubrik OS rubrik-8-1-3-p15-25607  |
|  2024-11-05T14:27:13.000Z|  ami-06e537a3af3d5f19a  |  Rubrik OS rubrik-8-1-3-p16-25670  |
|  2025-01-29T21:17:37.000Z|  ami-0803e67a19b1cd9d8  |  Rubrik OS rubrik-8-1-3-p17-25752  |
+--------------------------+-------------------------+------------------------------------+
```

## Known issues

There are a few known issues when using this Terraform module. These are described below.

### Deploying Cloud Cluster from the AWS Marketplace requires subscription

The Rubik product in the AWS Marketplace must be subscribed to. Otherwise an error like this will be displayed:
> Error: creating EC2 Instance: OptInRequired: In order to use this AWS Marketplace product you need to accept terms and subscribe. To do so please visit `https://aws.amazon.com/marketplace/pp?sku=<sku_number>`

If this occurs, open the specific link from the error, while logged into the AWS account where Cloud Cluster will be deployed. Follow the instructions for subscribing to the product.
For AWS GovCloud the link points to the public marketplace. Instead of following the link, launch one instance of the major version of Rubrik from the AWS console. This will accept the terms and subscribe to the subscription. Remove the manually launched instance and then run the Terraform again.

### Instance Metadata Service Version 2 (IMDSv2) not supported by CCES v8.1.2 and older

The AWS Instance Metadata Service Version 2 (IMDSv2) is not supported at this time with CCES v8.1.2 and older. This problem manifests itself after deploying the CCES node. SSH to the node fails to login and bootstrapping the node fails. When trying to ssh to the node the following error may occur:

```bash
admin@<node_ip_address>: Permission denied (publickey).
```

When trying to bootstrap the cluster the following error may occur in Terraform:

```log
rubrik_bootstrap_cces_aws.bootstrap_rubrik_cces_aws: Creating...
╷
│ Error: Error with cluster configuration parameters :  Error Failed to check cloud storage connectivity:
│ /0:0:0:0:0:0:0:1:
│ GENERIC Excepshun (InternalErrorCode(NullInternalErrorCode,)): "Check failed: \"\" != FLAGS_region ( vs. ) "}
│ *** Check failure stack trace: ***
│     @     0x7f55c52601c3  google::LogMessage::Fail()
│     @     0x7f55c526525b  google::LogMessage::SendToLog()
│     @     0x7f55c525febf  google::LogMessage::Flush()
│     @     0x7f55c52606ef  google::LogMessageFatal::~LogMessageFatal()
│     @     0x561bcdefac81  GetSpec()
│     @     0x561bcdeeb241  main
│     @     0x7f55c4a74083  __libc_start_main
│     @     0x561bcdef667e  _start in performBootstrap
│ 
│   with rubrik_bootstrap_cces_aws.bootstrap_rubrik_cces_aws,
│   on main.tf line 230, in resource "rubrik_bootstrap_cces_aws" "bootstrap_rubrik_cces_aws":
│  230: resource "rubrik_bootstrap_cces_aws" "bootstrap_rubrik_cces_aws" {
│ 
╵
```

Checking the bootstrap status using the REST API endpoint with a command such as `curl -X GET "https://<node_ip_address>/api/internal/cluster/me/bootstrap" -H "accept: application/json"` gives the error:

```json
{
  "status": "FAILURE",
  "message": "Error with cluster configuration parameters :  Error Failed to check cloud storage connectivity:\n/0:0:0:0:0:0:0:1:\nGENERIC Excepshun (InternalErrorCode(NullInternalErrorCode,)): \"Check failed: \\\"\\\" != FLAGS_region ( vs. ) \"}\n*** Check failure stack trace: ***\n    @     0x7f55c52601c3  google::LogMessage::Fail()\n    @     0x7f55c526525b  google::LogMessage::SendToLog()\n    @     0x7f55c525febf  google::LogMessage::Flush()\n    @     0x7f55c52606ef  google::LogMessageFatal::~LogMessageFatal()\n    @     0x561bcdefac81  GetSpec()\n    @     0x561bcdeeb241  main\n    @     0x7f55c4a74083  __libc_start_main\n    @     0x561bcdef667e  _start in performBootstrap",
  "ipConfig": "NOT_STARTED",
  "metadataSetup": "NOT_STARTED",
  "installSchema": "NOT_STARTED",
  "startServices": "NOT_STARTED",
  "ipmiConfig": "NOT_STARTED",
  "configAdminUser": "NOT_STARTED",
  "resetNodes": "NOT_STARTED",
  "setupDisks": "NOT_STARTED",
  "setupEncryptionAtRest": "NOT_STARTED",
  "setupOsAndMetadataPartitions": "NOT_STARTED",
  "createTopLevelFilesystemDirs": "NOT_STARTED",
  "setupLoopDevices": "NOT_STARTED",
  "clusterInstall": "NOT_STARTED"
}
```

If any of these errors occur, the Instance Metadata Service Version 2 (IMDSv2) may be enabled. This can happen if the option `aws_instance_imdsv2` is set to `true` in this module.  To fix this set the `aws_instance_imdsv2` variable to false or upgrade to CCES v8.1.3 and CCES v9.0 or higher.

[module-iam-policy]: ./iam_policy.json
