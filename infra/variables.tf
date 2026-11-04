variable "location" {
  description = "Azure region. Azure for Students only allows a few European regions; France Central is one of them."
  type        = string
  default     = "francecentral"
}

variable "environment" {
  description = "Environment name, used in resource names and tags."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be dev, staging or prod."
  }
}

variable "image" {
  description = "App image published by the cicd-visit-counter pipeline. Use an immutable sha- tag."
  type        = string
  default     = "ghcr.io/mrhamdichedli/visit-counter:sha-98a88c0"

  validation {
    condition     = !endswith(var.image, ":latest")
    error_message = "Use an immutable image tag, not latest."
  }
}

variable "min_replicas" {
  description = "0 lets the app scale to zero when idle (no compute cost), at the price of a cold start."
  type        = number
  default     = 0
}

variable "max_replicas" {
  type    = number
  default = 3
}

variable "monthly_budget" {
  description = "Monthly budget in the subscription's currency. Alerts at 50% and 90% spent, and at 100% forecast."
  type        = number
  default     = 10
}

variable "alert_email" {
  description = "Who receives the budget alerts. Set it in terraform.tfvars, which is not committed."
  type        = string
}

variable "budget_start_date" {
  description = "First day of the first budget month (must be the first day of a month)."
  type        = string
  default     = "2026-11-01T00:00:00Z"
}
