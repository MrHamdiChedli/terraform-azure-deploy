output "app_url" {
  description = "Public HTTPS address of the app"
  value       = "https://${azurerm_container_app.app.ingress[0].fqdn}"
}

output "database_host" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "resource_group" {
  value = azurerm_resource_group.main.name
}
