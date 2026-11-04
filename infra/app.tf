resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${local.name}-${var.environment}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = local.tags

  # The serverless Consumption profile: pay per use, scale to zero.
  # Note: Azure still creates this environment in "express" mode, which azurerm 4.x can't change.
  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

resource "azurerm_container_app" "app" {
  name                         = "ca-${local.name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"
  tags                         = local.tags

  lifecycle {
    # Express environments manage these themselves: they report 0 for both scaling timers
    # (which azurerm refuses as input), and store neither the traffic split (meaningless in
    # Single revision mode, but required by azurerm) nor the readiness probe's transport.
    # Without this, every plan would try to "fix" them.
    ignore_changes = [
      ingress[0].traffic_weight,
      template[0].cooldown_period_in_seconds,
      template[0].polling_interval_in_seconds,
      template[0].container[0].readiness_probe[0].transport,
    ]
  }

  secret {
    name  = "db-password"
    value = random_password.db.result
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    # One more replica per 20 requests in flight.
    http_scale_rule {
      name                = "http"
      concurrent_requests = "20"
    }

    # No init container: express environments reject them, so the app creates its table on first use.
    container {
      name   = "app"
      image  = var.image
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.main.fqdn
      }
      env {
        name  = "DB_USER"
        value = azurerm_postgresql_flexible_server.main.administrator_login
      }
      env {
        name  = "DB_NAME"
        value = azurerm_postgresql_flexible_server_database.app.name
      }
      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }

      # Traffic only goes to a replica that can reach the database.
      readiness_probe {
        transport = "HTTP"
        path      = "/healthz"
        port      = 8000
      }

      # Restart only if Gunicorn itself stops answering, never because of the database.
      liveness_probe {
        transport = "TCP"
        port      = 8000
      }
    }
  }
}
