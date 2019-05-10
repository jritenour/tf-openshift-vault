variable "kubehost" {
  description = "The kubernetes IP/FQDN, with http/https prefix & port if needed"
}


variable "namespace" {
  description = "The OpenShift project/namespace name"
}

variable "app_domain" {
  description = "The application domain name for openshift."
}
