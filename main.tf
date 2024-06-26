terraform {
  required_providers {
    mgc = {
      source = "magalucloud/mgc"
      version = "0.18.10"
    }
  }
}

resource "mgc_kubernetes_cluster" "cluster" {
  # Required
  name = var.name
  enabled_bastion = var.enabled_bastion
  node_pools = []

  # Optionals
  version = var.kubernetes_version
  description = var.description
  enabled_server_group = var.enabled_server_group
}

resource "time_sleep" "wait_15_minutes" {
  depends_on = [mgc_kubernetes_cluster.cluster]
  create_duration = "15m"
}

resource "mgc_kubernetes_nodepool" "nodepool" {
  for_each = { for np in var.node_pools : np.name => np }
  depends_on = [time_sleep.wait_15_minutes]

  cluster_id = mgc_kubernetes_cluster.cluster.id

  name     = each.value.name
  flavor   = each.value.flavor
  replicas = each.value.replicas
  
  auto_scale = {
    max_replicas = try(each.value.auto_scale.max_replicas, null)
    min_replicas = try(each.value.auto_scale.min_replicas, null)
  }

  tags   = try(each.value.tags, [])
  taints = try(each.value.taints, [])
}
