data "azurerm_subscription" "current" {}

# Email alerts before the student credit runs low. Azure for Students also has a hard
# spending limit: when the credit is gone, resources stop instead of being billed.
resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "budget-${local.name}"
  subscription_id = data.azurerm_subscription.current.id
  amount          = var.monthly_budget
  time_grain      = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  notification {
    enabled        = true
    threshold      = 50
    threshold_type = "Actual"
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 90
    threshold_type = "Actual"
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    threshold_type = "Forecasted"
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }
}
