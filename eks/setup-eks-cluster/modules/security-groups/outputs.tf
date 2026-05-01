output "cluster_sg_id" {
  value = aws_security_group.cluster.id
}

output "nodes_sg_id" {
  value = aws_security_group.nodes.id
}
