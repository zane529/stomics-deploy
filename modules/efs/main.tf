################################################################################
# 创建 EFS 安全组
################################################################################
resource "aws_security_group" "efs" {

  name        = "${var.eks_name}-efs-security-group"
  description = "Security group for EFS"
  vpc_id      = var.vpc_id

  # 允许来自 EKS 集群的 NFS 流量
  ingress {
    description     = "NFS from EKS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.eks_cluster_security_group_id]
  }

  # 允许所有出站流量
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.eks_name}-efs-security-group"
  }
}

################################################################################
# 创建 EFS 文件系统
################################################################################
resource "aws_efs_file_system" "efs" {
  creation_token = "${var.eks_name}-efs"
  tags = {
    Name = "${var.eks_name}-efs"
  }
}

################################################################################
# 创建 EFS 挂载目标
################################################################################
resource "aws_efs_mount_target" "efs" {
  depends_on = [ aws_efs_file_system.efs, aws_security_group.efs ]
  count           = 3
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

################################################################################
# 创建 Kubernetes StorageClass
################################################################################
resource "kubernetes_storage_class" "efs" {
  depends_on = [ aws_efs_file_system.efs ]
  metadata {
    name = "efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = aws_efs_file_system.efs.id
    directoryPerms   = "777"
    gidRangeStart: "1000"
    gidRangeEnd: "2000"
  }
}

################################################################################
# 创建 创建 Kubernetes PersistentVolume
################################################################################
resource "kubernetes_persistent_volume" "efs" {
  depends_on = [ aws_efs_file_system.efs, kubernetes_storage_class.efs ]
  metadata {
    name = "efs-pv"
  }
  spec {
    capacity = {
      storage = "4800Gi"
    }
    volume_mode = "Filesystem"
    access_modes = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name = kubernetes_storage_class.efs.metadata[0].name
    persistent_volume_source {
      csi {
        driver = "efs.csi.aws.com"
        volume_handle = aws_efs_file_system.efs.id
      }
    }
  }
}

################################################################################
# 创建 Kubernetes PersistentVolumeClaim
################################################################################
resource "kubernetes_persistent_volume_claim" "efs" {
  depends_on = [ aws_efs_file_system.efs, kubernetes_storage_class.efs, kubernetes_persistent_volume.efs ]
  metadata {
    name = "efs-pvc"
    namespace = "default"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class.efs.metadata[0].name
    resources {
      requests = {
        storage = "4800Gi"
      }
    }
  }
}