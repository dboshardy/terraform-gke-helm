provider "kubernetes" {
  host     = "${google_container_cluster.default.endpoint}"
  username = "${var.gke_username}"
  password = "${var.gke_password}"

  client_certificate     = "${base64decode(google_container_cluster.default.master_auth.0.client_certificate)}"
  client_key             = "${base64decode(google_container_cluster.default.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.default.master_auth.0.cluster_ca_certificate)}"
}

resource "kubernetes_namespace" "dev" {
  metadata {
    name = "dev"
  }
}

resource "google_compute_address" "default" {
  name = "tf-gke-k8s-lb"
}

// Ingress service definition - so k8s is accessible from the outside on TCP 80

resource "kubernetes_service" "nginx" {
  metadata {
    namespace = "${kubernetes_namespace.dev.metadata.0.name}"
    name      = "nginx"
  }

  spec {
    selector {
      run = "nginx"
    }

    session_affinity = "ClientIP"

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }

    type             = "LoadBalancer"
    load_balancer_ip = "${google_compute_address.default.address}"
  }
}

resource "kubernetes_replication_controller" "nginx" {
  metadata {
    name      = "nginx"
    namespace = "${kubernetes_namespace.dev.metadata.0.name}"

    labels {
      run = "nginx"
    }
  }

  spec {
    selector {
      run = "nginx"
    }

    template {
      container {
        image = "nginx:latest"
        name  = "nginx"

        resources {
          limits {
            cpu    = "0.5"
            memory = "512Mi"
          }

          requests {
            cpu    = "250m"
            memory = "50Mi"
          }
        }
      }
    }
  }
}
