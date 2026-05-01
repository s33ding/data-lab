output "cluster_name" {
  value = module.cluster.cluster_name
}

output "cluster_endpoint" {
  value = module.cluster.cluster_endpoint
}

output "cluster_ca_certificate" {
  value     = module.cluster.cluster_ca_certificate
  sensitive = true
}
