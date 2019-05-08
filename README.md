# Deploy HashiCorp Vault (and Consul) on OpenShift with Terraform

This will deploy Vault & Consul on OpenShift using Terraform (tested on 3.10 & 3.11).  Vault will use Consul as a storage backend, and Consul will manage the Vault Cluster.

You will need to define the follow variables

 "kubehost" = The kubernetes IP/FQDN, with http/https prefix & port if needed. eg "https://opeshift.example.com:8443"

"kubeuser" = The kubernetes user to authenticate as.

"kubepass" = The kubernetes password.

*NOTE:* Kubernetes user/passwould should not be required if you have an existing OpenShift token

"namespace" = The OpenShift project/namespace name you will be creating to deploy Vault in.  
