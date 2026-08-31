# variables.tf
# Define basic parameters for the workspace so they can be easily adjusted by the PM/Admin later.

variable "workspace_namespace" {
  description = "The Kubernetes namespace where developer workspaces will be provisioned."
  type        = string
  default     = "coder"
}

variable "cpu_limit" {
  description = "The maximum CPU limit assigned to the workspace pod (e.g., '2', '4', '500m')."
  type        = string
  default     = "2"
}

variable "memory_limit" {
  description = "The maximum memory limit assigned to the workspace pod (e.g., '4Gi', '8Gi')."
  type        = string
  default     = "4Gi"
}

variable "pvc_size" {
  description = "The size of the Persistent Volume Claim (PVC) mounted to /home/coder."
  type        = string
  default     = "10Gi"
}

variable "use_kubeconfig" {
  type        = bool
  description = "Set to true if authenticating to Kubernetes from outside the cluster (e.g., local CLI deployment)."
  default     = false
}
