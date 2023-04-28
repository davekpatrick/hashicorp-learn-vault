# BOF
terraform {
  required_version = "~> 1.4"
  required_providers {
    vault = {
      source  = "registry.terraform.io/hashicorp/vault"
      version = "~> 3.15"
    }
  }
}
# ------------------------------------------------------------
provider "vault" {
  namespace = "admin"
  skip_child_token = true
}
# ------------------------------------------------------------
locals {
  productServices = flatten([ for i, data in var.products : [
    for j in data["services"] : {
      "name" = "${i}-${j}",
      "product" = i,
      "service" = j,
      "environments" = data["environments"],
      #
      "config" = data
    } 
  ]])
  productServiceInstances = { for i, data in local.productServices : 
     data["name"] => {
      "service" = data["service"],
      "product" = data["product"],
      "environments" = data["environments"],
      #
      "config" = data["config"]
     }
  }
  serviceEnvironments = flatten([ for i, data in local.productServiceInstances : [
    for j in data["environments"] : {
      "name" = "${i}-${j}",
      "product" =  data["product"],
      "service" = data["service"],
      "environment" = j,
      #
      "config" = data["config"]
    } 
  ]])
  serviceEnvironmentInstances = { for i, data in local.serviceEnvironments : 
     data["name"] => {
      "product" = data["product"],
      "service" = data["service"],
      "environment" = data["environment"],
      #
      "config" = data["config"]
     }
  }
  #
  out_config = { for i, data in var.products :
   i  => {
      "name" = data["name"],
      "namespace" = var.namespace,
      #
      "config" = data
    }
  }
}
# ------------------------------------------------------------
resource "vault_github_auth_backend" "default" {
  namespace = resource.vault_namespace.default.path
  organization = var.namespace
}
resource "vault_github_team" "admin" {
  namespace = resource.vault_namespace.default.path
  backend = resource.vault_github_auth_backend.default.id
  team = "administrators"
  policies = ["default", "admin"]
}
resource "vault_github_team" "bender" {
  namespace = resource.vault_namespace.default.path
  backend = resource.vault_github_auth_backend.default.id
  team = "bender"
  policies = [ resource.vault_policy.benderProductionSupport.name ]
}
resource "vault_github_team" "fry" {
  namespace = resource.vault_namespace.default.path
  backend = resource.vault_github_auth_backend.default.id
  team = "fry"
  policies = [ resource.vault_policy.denyFry.name, resource.vault_policy.fry.name ]
}
# ------------------------------------------------------------
resource "vault_policy" "admin" {
  namespace = resource.vault_namespace.default.path
  name = "admin"
  policy = <<EOT
    path "sys/*"
    {
      capabilities = ["read", "list"]
    }
    path "sys/policies/acl/*"
    {
      capabilities = ["create", "read", "update", "delete", "list"]
    }
    path "auth/*"
    {
      capabilities = ["create", "read", "update","list"]
    }
    path "sys/auth/*"
    {
      capabilities = ["create", "read", "update","list", "sudo"]
    }
    path "/auth/token/create-orphan" {
      capabilities = ["deny"]
    }
    path "identity/*" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }
    path "sys/mounts/*"
    {
      capabilities = ["create", "read", "update", "delete", "list"]
    }
    path "*"
    {
      capabilities = ["create", "read", "update", "delete", "list"]
    }
  EOT
}
resource "vault_policy" "denyBender" {
  namespace = resource.vault_namespace.default.path
  name = "benderDeny"
  policy = <<EOT
  path "bender/data/.info"
  {
    capabilities = ["deny"]
  }
  path "bender/data/+/ps"
  {
    capabilities = ["deny"]
  }
  path "bender/data/+/ps/*"
  {
    capabilities = ["deny"]
  }
  EOT
}
resource "vault_policy" "denyFry" {
  namespace = resource.vault_namespace.default.path
  name = "fryDeny"
  policy = <<EOT
  path "fry/data/.info"
  {
    capabilities = ["deny"]
  }
  path "fry/data/+/ps"
  {
    capabilities = ["deny"]
  }
  path "fry/data/+/ps/*"
  {
    capabilities = ["deny"]
  }
  EOT
}
resource "vault_policy" "bender" {
  namespace = resource.vault_namespace.default.path
  name = "bender"
  policy = <<EOT
  path "bender/metadata/*"
  {
    capabilities = ["list"]
  }
  path "bender/destroy/*"
  {
    capabilities = ["update"]
  }
  path "bender/delete/*"
  {
    capabilities = ["update"]
  }

  path "bender/undelete/*"
  {
    capabilities = ["update"]
  }
  path "bender/*"
  {
    capabilities = ["create", "update", "read", "list"]
  }
  EOT
}
resource "vault_policy" "fry" {
  namespace = resource.vault_namespace.default.path
  name = "fry"
  policy = <<EOT
  path "fry/metadata/*"
  {
    capabilities = ["list"]
  }
  path "fry/destroy/*"
  {
    capabilities = ["update"]
  }
  path "fry/delete/*"
  {
    capabilities = ["update"]
  }

  path "fry/undelete/*"
  {
    capabilities = ["update"]
  }
  path "fry/*"
  {
    capabilities = ["create", "update", "read", "list"]
  }
  EOT
}
resource "vault_policy" "benderProductionSupport" {
  namespace = resource.vault_namespace.default.path
  name = "benderProductionSupport"
  policy = <<EOT
  path "bender/metadata/*"
  {
    capabilities = ["list"]
  }
  path "bender/data/+/ps"
  {
    capabilities = ["create", "update", "read", "list"]
  }
  path "bender/data/+/ps/*"
  {
    capabilities = ["create", "update", "read", "list"]
  }
  EOT
}
resource "vault_policy" "fryProductionSupport" {
  namespace = resource.vault_namespace.default.path
  name = "fryProductionSupport"
  policy = <<EOT
  path "fry/metadata/*"
  {
    capabilities = ["list"]
  }
  path "fry/data/+/ps"
  {
    capabilities = ["create", "update", "read", "list"]
  }
  path "fry/data/+/ps/*"
  {
    capabilities = ["create", "update", "read", "list"]
  }
  EOT
}
# ------------------------------------------------------------
resource "vault_namespace" "default" {
  #
  path = var.namespace  
}
resource "vault_mount" "default" {
  for_each = var.products
  #
  namespace = resource.vault_namespace.default.path
  path = each.key
  type = each.value["type"]
  options = each.value["options"]
  description = each.value["description"]
}
resource "vault_generic_secret" "default" {
  for_each = var.products
  #
  namespace = resource.vault_mount.default[each.key].namespace
  path = format("%s/.info", resource.vault_mount.default[each.key].path)
 
  data_json = jsonencode( {
    "key" = each.key
    "name" = each.value["name"]
    "managed-by" = each.value["managed-by"]
  })
}
resource "vault_generic_secret" "service" {
  for_each = local.productServiceInstances
  #
  namespace = resource.vault_mount.default[each.value["product"]].namespace
  path = format("%s/%s", resource.vault_mount.default[each.value["product"]].path, each.value["service"] )
  #
  data_json = jsonencode( {
    "key" = each.key
    "name" = each.value["config"]["name"]
    "managed-by" = each.value["config"]["managed-by"]
  })
}
resource "vault_generic_secret" "environment" {
  for_each = local.serviceEnvironmentInstances
  #
  namespace = resource.vault_mount.default[each.value["product"]].namespace
  path = format("%s/%s/%s", resource.vault_mount.default[each.value["product"]].path, each.value["service"], each.value["environment"] )
  #
  data_json = jsonencode( {
    "key" = each.key
    "name" = each.value["config"]["name"]
    "managed-by" = each.value["config"]["managed-by"]
  })
}
# ------------------------------------------------------------
resource "vault_generic_secret" "testCases" {
  for_each = var.testCases
  #
  namespace = resource.vault_mount.default[each.value["product"]].namespace
  path = format("%s/%s", 
      resource.vault_mount.default[each.value["product"]].path, 
      each.value["path"]
      )
  #
  data_json = jsonencode( {
    "test" = "can you see me?"
  })
}
# EOF