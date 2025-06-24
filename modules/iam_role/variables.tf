variable "bucket_arn" {
  type = string
}

variable "enable_immutability" {
  type    = bool
  default = null

  validation {
    condition     = var.enable_immutability == null ? var.enableImmutability != null : true
    error_message = "enable_immutability must be specified."
  }
}

variable "instance_profile_name" {
  type = string
}

variable "role_managed_policies" {
  type        = set(string)
  default     = []
  description = "Set of IAM managed policy ARNs to attach to the IAM role."
}

variable "role_name" {
  type = string
}

variable "role_permission_boundary" {
  type        = string
  default     = null
  description = "ARN of the policy that is used to set the permissions boundary for the role."
}

variable "role_policy_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

# Deprecated variables.

variable "enableImmutability" {
  type        = bool
  default     = null
  description = "Deprecated: use enable_immutability instead."
}

check "deprecations" {
  assert {
    condition     = var.enableImmutability == null
    error_message = "The enableImmutability variable has been deprecated, use enable_immutability instead."
  }
}
