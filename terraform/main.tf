terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Defina as variaveis para facilitar a configuracao
variable "subscription_id" {
  type        = string
  description = "Sua Subscription ID do Azure"
  default     = "<SUA_SUBSCRIPTION_ID>"
}

variable "resource_group_name" {
  default = "rg-tcc-ia"
}

variable "location" {
  default = "eastus2" # Escolha uma regiao Azure proxima a voce
}

variable "storage_account_name" {
  default = "stctccia"
  # Adicione um sufixo para garantir a unicidade
}

variable "container_name" {
  default = "pdfs"
}

variable "search_service_name" {
  default = "srch-tcc-ia"
}

variable "aml_workspace_name" {
  default = "amlw-tcc-ia"
}

variable "openai_service_name" {
  default = "aoai-tcc-ia"
}

# 1. Grupo de Recursos
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# 2. Conta de Armazenamento (para armazenar os PDFs)
resource "azurerm_storage_account" "sa" {
  name                     = lower(var.storage_account_name)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 3. Container na Conta de Armazenamento
resource "azurerm_storage_container" "container" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

# 4. Azure Cognitive Search Service
resource "azurerm_cognitive_search_service" "search_service" {
  name                = var.search_service_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "standard" # Escolha o SKU adequado para sua necessidade
  replica_count       = 1
  partition_count     = 1
}

# 5. Azure Machine Learning Workspace
resource "azurerm_machine_learning_workspace" "aml_workspace" {
  name                    = var.aml_workspace_name
  resource_group_name     = azurerm_resource_group.rg.name
  location                = var.location
  storage_account_id      = azurerm_storage_account.sa.id
  identity {
    type = "SystemAssigned"
  }
}

# 6. Azure OpenAI Service Account
resource "azurerm_cognitive_account" "openai_account" {
  name                = var.openai_service_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  kind                = "OpenAI"
  sku_name            = "S0"
}

# 7. Azure OpenAI Service Deployment for Embeddings
resource "azurerm_cognitive_deployment" "openai_embedding_deployment" {
  name                = "text-embedding-ada-002"
  cognitive_account_id = azurerm_cognitive_account.openai_account.id
  model {
    name    = "text-embedding-ada-002"
    version = "2"
    format  = "OpenAI"
  }
  scale {
    type = "Standard"
  }
}

# 8. Azure OpenAI Service Deployment for Completions (Chat)
resource "azurerm_cognitive_deployment" "openai_completion_deployment" {
  name                = "gpt-35-turbo"
  cognitive_account_id = azurerm_cognitive_account.openai_account.id
  model {
    name    = "gpt-35-turbo"
    version = "0613"
    format  = "OpenAI"
  }
  scale {
    type = "Standard"
  }
}

# 9. Azure Container Instances (para hospedar a aplicacao do chat - Opcional, mas recomendado para um exemplo completo)
resource "azurerm_container_group" "aci_chat_app" {
  name                = "aci-chat-app"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  ip_address_type     = "Public"
  os_type             = "Linux"
  container {
    name    = "chat-app-container"
    image   = "seu-registro-docker/sua-imagem-chat-app:latest" # Substitua pela sua imagem Docker da aplicacao de chat
    cpu     = 1
    memory  = 1.5
    ports {
      port     = 80
      protocol = "TCP"
    }
    environment_variables = {
      SEARCH_SERVICE_ENDPOINT = azurerm_cognitive_search_service.search_service.endpoint
      SEARCH_SERVICE_ADMIN_KEY = azurerm_cognitive_search_service.search_service.admin_key
      OPENAI_API_KEY          = azurerm_cognitive_account.openai_account.primary_access_key
      OPENAI_EMBEDDING_DEPLOYMENT_NAME = azurerm_cognitive_deployment.openai_embedding_deployment.name
      OPENAI_COMPLETION_DEPLOYMENT_NAME = azurerm_cognitive_deployment.openai_completion_deployment.name
    }
  }
  depends_on = [
    azurerm_cognitive_search_service.search_service,
    azurerm_cognitive_account.openai_account,
    azurerm_cognitive_deployment.openai_embedding_deployment,
    azurerm_cognitive_deployment.openai_completion_deployment
  ]
}
