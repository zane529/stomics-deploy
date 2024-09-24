



resource "kubernetes_manifest" "2048-node" {
  manifest = yamldecode(file("2048-node.yaml"))
}

resource "kubernetes_manifest" "vision" {
  manifest = yamldecode(file("2048-node.yaml"))
}