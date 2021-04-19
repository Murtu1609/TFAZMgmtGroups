

provider "random" {
  version = "~> 2.2"
}

resource "random_string" "rstring" {
  length  = 5
  special = false
  upper   = true
  lower   = true
  number  = true
}

locals {
  groups = csvdecode(file("mgmtgroups.csv"))
}

data "azurerm_management_group" "startgroup" {
  for_each = var.starting_group == "na" ? [] : toset([var.starting_group])
  name = var.starting_group
  
}

resource "azurerm_management_group" "layer1"{
for_each = {for object in local.groups : object.layer1 => object if object.layer2 == ""}
name = "${each.key}-${random_string.rstring.result}"
display_name = each.key
subscription_ids = each.value.subs == "" ? null : split(",",each.value.subs)
parent_management_group_id = var.starting_group == "na" ? null : data.azurerm_management_group.startgroup[var.starting_group].id
}

resource "azurerm_management_group" "layer2"{
for_each = {for object in local.groups : "${object.layer2}-${object.layer1}" => object if object.layer2 != "" && object.layer3 == ""}
name = each.key
display_name = each.value.layer2
subscription_ids = each.value.subs == "" ? null : split(",",each.value.subs)
parent_management_group_id = azurerm_management_group.layer1[each.value.layer1].id
}

resource "azurerm_management_group" "layer3"{
for_each = {for object in local.groups : "${object.layer3}-${object.layer2}-${object.layer1}" => object if object.layer3 != "" && object.layer4 == ""}
name = each.key
display_name = each.value.layer3
subscription_ids = each.value.subs == "" ? null : split(",",each.value.subs)
parent_management_group_id = azurerm_management_group.layer2["${each.value.layer2}-${each.value.layer1}"].id
}

resource "azurerm_management_group" "layer4"{
for_each = {for object in local.groups : "${object.layer4}-${object.layer3}-${object.layer2}-${object.layer1}" => object if object.layer4 != "" && object.layer5 == ""}
name = each.key
display_name = each.value.layer4
subscription_ids = each.value.subs == "" ? null : split(",",each.value.subs)
parent_management_group_id = azurerm_management_group.layer3["${each.value.layer3}-${each.value.layer2}-${each.value.layer1}"].id
}

resource "azurerm_management_group" "layer5"{
for_each = {for object in local.groups : "${object.layer5}-${object.layer4}-${object.layer3}-${object.layer2}-${object.layer1}" => object if object.layer5 != ""}
name = each.key
display_name = each.value.layer5
subscription_ids = each.value.subs == "" ? null : split(",",each.value.subs)
parent_management_group_id = azurerm_management_group.layer4["${each.value.layer4}-${each.value.layer3}-${each.value.layer2}-${each.value.layer1}"].id
}
