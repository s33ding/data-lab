data "aws_vpc" "existing" {
  id = var.vpc_id
}

module "iam" {
  source       = "./modules/iam"
  cluster_name = var.cluster_name
}

module "security_groups" {
  source       = "./modules/security-groups"
  cluster_name = var.cluster_name
  vpc_id       = var.vpc_id
  vpc_cidr     = data.aws_vpc.existing.cidr_block
}

module "cluster" {
  source           = "./modules/cluster"
  cluster_name     = var.cluster_name
  cluster_role_arn = module.iam.cluster_role_arn
  node_role_arn    = module.iam.node_role_arn
  subnet_ids       = var.subnet_ids
  cluster_sg_id    = module.security_groups.cluster_sg_id

  depends_on = [
    module.iam,
    module.security_groups,
  ]
}

# --- OIDC Provider ---

data "tls_certificate" "eks" {
  url = module.cluster.oidc_issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = module.cluster.oidc_issuer
}

# --- EBS CSI IAM Role ---

locals {
  oidc_id = replace(module.cluster.oidc_issuer, "https://", "")
}

resource "aws_iam_role" "ebs_csi" {
  name = "${var.cluster_name}-ebs-csi-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_id}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${local.oidc_id}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi.name
}

# --- EBS CSI Addon (after OIDC role is ready) ---

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = module.cluster.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs_csi.arn
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_iam_role_policy_attachment.ebs_csi]
}

# --- ALB Controller IAM Role ---

resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_id}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller-sa"
          "${local.oidc_id}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "alb_controller" {
  name   = "${var.cluster_name}-alb-controller-policy"
  policy = file("${path.module}/policies/alb-iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  policy_arn = aws_iam_policy.alb_controller.arn
  role       = aws_iam_role.alb_controller.name
}
