provider "google" {
  region = "us-east1"
}

resource "google_compute_network" "myvpc1" {
  name = "vpc-for-webserver"
  auto_create_subnetworks = false
}
resource "google_compute_subnetwork" "mysubnet1" {
  network = google_compute_network.myvpc1.id
  ip_cidr_range = "10.0.1.0/24"
  name = "mysubnet-for-webserver"
}

resource "google_compute_address" "address" {
  name = "external_static_ip"
  address_type = "EXTERNAL"
}

#loadbalancing-configuration

resource "google_compute_forwarding_rule" "forwadingrule" {
  name = "forwading-rule"
  ip_address = google_compute_address.address.id
  target = google_compute_target_http_proxy.proxyone.id
}

resource "google_compute_target_http_proxy" "proxyone" {
  name = "proxyname"
  url_map = google_compute_url_map.urlone.id
}
resource "google_compute_url_map" "urlone" {
  name = "urlmaping"
  default_service = google_compute_backend_service.backendone.id
}
resource "google_compute_backend_service" "backendone" {
  name = "backendservices"
  backend {
    group = google_compute_instance_group_manager.mig1.instance_group
  }
  health_checks = [google_compute_http_health_check.healthcheckone.id]
}
resource "google_compute_http_health_check" "healthcheckone" {
  name = "healthcheckforweb"
  
}

#instance-template

resource "google_compute_instance_template" "template1" {
  name = "templateone"
  machine_type = "e2-medium"
  disk {
    source_image = "projects/debian-cloud/global/images/family/debian-11"
    auto_delete = true
    boot = true
  }
  network_interface {
    network = google_compute_network.myvpc1.id
    subnetwork = google_compute_subnetwork.mysubnet1.id
    access_config {
      nat_ip = google_compute_address.address.address
    }
  }
}

#managed-instance-group 

resource "google_compute_instance_group_manager" "mig1" {
  name = "managedinstance"
  base_instance_name = "webserver"
  version {
      instance_template = google_compute_instance_template.template1.id
  }
  zone = "us-east1-a"
  target_size = 3
  named_port {
    name = "http"
    port = 80
  }
}

#instance-creation

resource "google_compute_instance" "myinstance1" {
  name = "webserver"
  machine_type = "e2-micro"
  zone = "us-east1-a"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  metadata = {
    ssh-keys = "username:ssh-rsa YOUR_SSH_KEY"
    startup-script-url = "gs://mybucketnameone/bucketobjectone.sh"
  }
  network_interface {
    network = google_compute_network.myvpc1.name
    subnetwork = google_compute_subnetwork.mysubnet1.id
    access_config {
       
    }
  }
}

#firewall 

resource "google_compute_firewall" "ssh" {
  name = "firewall-for-webserver"
  network = google_compute_network.myvpc1.id
  allow {
    ports = ["22"]
    protocol = "tcp"
  }
  source_ranges = ["0.0.0.0/0"]
}
