variable "kubehost" {
  description = "The kubernetes IP/FQDN, with http/https prefix & port if needed"
}

variable "kubeuser" {
  description = "The kubernetes user to authenticate as"
}

variable "kubepass" {
  description = "The kubernetes password"
}

variable "namespace" {
  description = "The OpenShift project/namespace name"
}
