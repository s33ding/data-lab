resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = "1.35"

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.cluster_sg_id]
  }
}

# --- Node Groups ---

resource "aws_eks_node_group" "on_demand" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "on-demand"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  capacity_type   = "ON_DEMAND"
  instance_types  = ["c4.large"]
  disk_size       = 20

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 0
  }

  labels = { role = "kube-system" }
}

resource "aws_eks_node_group" "spot" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "spot"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  capacity_type   = "SPOT"
  instance_types  = ["t3.large"]
  disk_size       = 20

  scaling_config {
    desired_size = 1
    max_size     = 5
    min_size     = 1
  }

  labels = { node-type = "spot" }
}

# --- Addons ---

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
}
