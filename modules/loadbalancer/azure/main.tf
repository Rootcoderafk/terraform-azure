# Azure Application Gateway Module
# Creates Application Gateway with HTTPS listener

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Public IP for Application Gateway
resource "azurerm_public_ip" "appgw" {
  name                = "${var.environment}-appgw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.environment}-nginx-${random_string.dns_suffix.result}"

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Random string for unique DNS name
resource "random_string" "dns_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = "${var.environment}-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = var.capacity
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  # Self-signed SSL certificate
  ssl_certificate {
    name     = "${var.environment}-ssl-cert"
    data     = filebase64("${path.module}/cert.pfx")
    password = var.ssl_certificate_password
  }
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101S"
  }

  backend_address_pool {
    name         = "nginx-backend-pool"
    ip_addresses = var.backend_ips
  }

  backend_http_settings {
    name                  = "https-backend-settings"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
    pick_host_name_from_backend_address = false
    probe_name            = "https-health-probe"
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "https-port"
    protocol                       = "Https"
    ssl_certificate_name           = "${var.environment}-ssl-cert"
  }

  # HTTP listener for redirect
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "https-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "nginx-backend-pool"
    backend_http_settings_name = "https-backend-settings"
    priority                   = 100
  }

  # HTTP to HTTPS redirect rule
  redirect_configuration {
    name                 = "http-to-https-redirect"
    redirect_type        = "Permanent"
    target_listener_name = "https-listener"
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name                        = "http-redirect-rule"
    rule_type                   = "Basic"
    http_listener_name          = "http-listener"
    redirect_configuration_name = "http-to-https-redirect"
    priority                    = 200
  }

  probe {
    name                = "https-health-probe"
    protocol            = "Https"
    path                = "/health"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    pick_host_name_from_backend_http_settings = false
    host                = "127.0.0.1"
    match {
      status_code = ["200-399"]
    }
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
