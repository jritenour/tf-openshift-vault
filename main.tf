provider "kubernetes" {
  host = "${var.kubehost}"
#  username = "${var.kubeuser}"
#  password = "${var.kubepass}"
}

resource "kubernetes_namespace" "vault-deploy" {
  metadata {
    annotations {
      name = "vault-deploy"
    }

    labels {
      app = "vault"
    }
    name = "vault-deploy"
  }
}

resource "kubernetes_service" "consul" {
  metadata  {
    labels  {
      app =  "consul"
    },
    name = "consul",
    namespace = "vault-deploy"
  },
  spec  {
    selector  {
      app = "consul"
    },
    session_affinity = "None",
    type = "ClusterIP",
    port  {

        name =  "http",
        port =  8500,
        protocol = "TCP",
        target_port = 8500
      }
    port  {
        name = "https",
        port = 8443,
        protocol = "TCP",
        target_port = 8443
      }
    port  {
        name = "rpc",
        port = 8400,
        protocol = "TCP",
        target_port = 8400
      }
    port  {
        name = "serflan-tcp",
        port = 8301,
        protocol = "TCP",
        target_port = 8301
      }
    port  {
        name = "serflan-udp",
        port = 8301,
        protocol = "UDP",
        target_port = 8301
      }
    port  {
        name = "serfwan-tcp",
        port = 8302,
        protocol = "TCP",
        target_port = 8302
      }
    port  {
        name = "serfwan-udp",
        port = 8302,
        protocol = "UDP",
        target_port = 8302
      }
    port  {
        name = "server",
        port = 8300,
        protocol = "TCP",
        target_port = 8300
      }
    port  {
        name = "consuldns",
        port = 8600,
        protocol = "TCP",
        target_port = 8600
      }
    }

  }

  resource "kubernetes_service" "vault" {
    metadata  {
      labels  {
        app =  "vault"
      },
      name= "vault",
      namespace= "vault-deploy"
    },
    spec= {
      port = [
        {
          name= "vault",
          port= 8200,
          protocol= "TCP",
          target_port= 8200
        }
      ],
      selector= {
        app= "vault"
      },
      session_affinity= "None",
      type= "ClusterIP"
    }
  }

  resource "kubernetes_config_map" "vault" {
  "metadata"= {
    "name"= "vault",
    "namespace"= "vault-deploy"
  }
  data {
  vault.hcl = "storage \"consul\" {\n address = \"127.0.0.1:8500\"\n path = \"vault/\"\n }\nlistener \"tcp\" {\n  address = \"0.0.0.0:8200\"\n  tls_disable = \"true\"\n}\ndisable_mlock=\"true\"\ndisable_cache=\"true\"\nui = \"true\"\n\nmax_least_ttl=\"10h\"\ndefault_least_ttl=\"10h\"\nraw_storage_endpoint=true\ncluster_name=\"mycompany-vault\"\n"
},
}

  resource "kubernetes_service_account" "privilegeduser" {
    metadata {
      name = "privilegeduser"
      namespace = "vault-deploy"
    }
  }

  resource "kubernetes_stateful_set" "consul"{
    metadata= {
      name= "consul",
      namespace= "vault-deploy",
    },
    spec= {
      pod_management_policy= "OrderedReady",
      replicas= 1,
      revision_history_limit= 10,
      selector= {
        match_labels= {
          app= "consul"
        }
      },
      service_name= "consul",
      template= {
        metadata= {
        labels {
        app = "consul"
        }
        },
        spec= {
          container= [
            {
              args= [
                "agent",
                "-advertise=$(POD_IP)",
                "-bind=0.0.0.0",
                "-bootstrap-expect=1",
                "-retry-join=consul-0.consul.vault-deploy.svc.cluster.local",
                "-client=0.0.0.0",
                "-datacenter=dc1",
                "-data-dir=/consul/data",
                "-domain=cluster.local",
                "-server",
                "-ui",
                "-disable-host-node-id"
              ],
              env= [
                {
                  name= "POD_IP",
                  value_from= {
                    field_ref= {
                      field_path= "status.podIP"
                    }
                  }
                },
              ],
              image= "consul:latest",
              image_pull_policy= "IfNotPresent",
              lifecycle= {
                pre_stop= {
                  exec= {
                    command= [
                      "/bin/sh",
                      "-c",
                      "consul leave"
                    ]
                  }
                }
              },
              name= "consul",
                port {
                  container_port= 8500,
                  name= "ui-port",
                  protocol= "TCP"
                },
                port {
                  container_port= 8400,
                  name= "alt-port",
                  protocol= "TCP"
                },
                port {
                  container_port= 53,
                  name= "udp-port",
                  protocol= "TCP"
                },
                port {
                  container_port= 8443,
                  name= "https-port",
                  protocol= "TCP"
                },
                port {
                  container_port= 8080,
                  name= "http-port",
                  protocol= "TCP"
                },
                port {
                  container_port= 8301,
                  name= "serflan",
                  protocol= "TCP"
                },
                port {
                  container_port= 8302,
                  name= "serfwan",
                  protocol= "TCP"
                },
                port {
                  container_port= 8600,
                  name= "consuldns",
                  protocol= "TCP"
                },
                port {
                  container_port= 8300,
                  name= "server",
                  protocol= "TCP"
                }
              resources= {},
              "termination_message_path"= "/dev/termination-log",
              "volume_mount"= [
                {
                  "mount_path"= "/consul/data",
                  name= "data"
                }
              ]
            }
          ],
          dns_policy= "ClusterFirst",
          restart_policy= "Always",
          security_context= {
            fs_group= 1000
          },
          service_account_name= "privilegeduser",
          termination_grace_period_seconds= 10
        }
      },
      update_strategy= {
        rolling_update= {
          partition= 0
        },
        type= "RollingUpdate"
      },
      volume_claim_template= [
        {
          metadata= {
            name= "data"
          },
          spec= {
            access_modes= [
              "ReadWriteOnce"
            ],
            resources= {
              requests= {
                storage= "1Gi"
              }
            }
          }
        }
      ]
    }
  }

  resource "kubernetes_stateful_set" "vault" {
    "metadata"= {
      "labels"= {
        "app"= "vault"
      },
      "name"= "vault",
      "namespace"= "vault-deploy",
    },
    "spec"= {
      "pod_management_policy"= "OrderedReady",
      "replicas"= 1,
      "selector"= {
        "match_labels"= {
          "app"= "vault"
        }
      },
      "service_name"= "vault",
      "template"= {
        "metadata"= {
          "labels"= {
            "app"= "vault"
          }
        },
        "spec"= {
          "container"= [
            {
              "command"= [
                "vault",
                "server",
                "-config",
                "/vault/config/vault.hcl"
              ],
              "env"= [
                {
                  "name"= "HOST_IP",
                  "value_from"= {
                    "field_ref"= {
                      "field_path"= "status.hostIP"
                    }
                  }
                },
                {
                  "name"= "POD_IP",
                  "value_from"= {
                    "field_ref"= {
                      "field_path"= "status.podIP"
                    }
                  }
                },
                {
                  "name"= "NAMESPACE",
                  "value_from"= {
                    "field_ref"= {
                      "field_path"= "metadata.namespace"
                    }
                  }
                }
              ],
              "image"= "vault:latest",
              "image_pull_policy"= "IfNotPresent",
              "lifecycle"= {
                "pre_stop"= {
                  "exec"= {
                    "command"= [
                      "vault operator step-down"
                    ]
                  }
                }
              },
              "name"= "vault",
              "port"
                {
                  "container_port"= 8200,
                  "name"= "vault-port",
                  "protocol"= "TCP"
                },
              port  {
                  "container_port"= 8201,
                  "name"= "cluster-port",
                  "protocol"= "TCP"
                }
              "resources"= {},
              "security_context"= {
                "capabilities"= {
                  "add"= [
                    "IPC_LOCK"
                  ]
                }
              },
              "termination_message_path"= "/dev/termination-log",
              "volume_mount"= [
                {
                  "mount_path"= "/vault/config/vault.hcl",
                  "name"= "configurations",
                  "sub_path"= "vault.hcl"
                }
              ]
            },
            {
              "args"= [
                "agent",
                "-retry-join=consul-0.consul.vault-deploy.svc.cluster.local",
                "-domain=cluster.local",
                "-datacenter=dc1",
                "-disable-host-node-id",
                "-client=127.0.0.1",
                "-bind=$(POD_IP)"
              ],
              "env"= [
                {
                  "name"= "POD_IP",
                  "value_from"= {
                    "field_ref"= {
                      "field_path"= "status.podIP"
                    }
                  }
                },
                {
                  "name"= "NAMESPACE",
                  "value_from"= {
                    "field_ref"= {
                      "field_path"= "metadata.namespace"
                    }
                  }
                }
              ],
              "image"= "consul",
              "image_pull_policy"= "IfNotPresent",
              "name"= "consul-vault-agent",
              "resources"= {},
              "termination_message_path"= "/dev/termination-log",
              "volume_mount"= [
                {
                  "mount_path"= "/consul/data",
                  "name"= "data"
                }
              ]
            }
          ],
          "dns_policy"= "ClusterFirst",
          "restart_policy"= "Always",
          "security_context"= {},
          "service_account_name"= "privilegeduser",
          "termination_grace_period_seconds"= 10,
          "volume"= [
            {
              "config_map"= {
                "name"= "vault"
              },
              "name"= "configurations"
            }
          ]
        }
      },
      "update_strategy"= {
        "rolling_update"= {
          "partition"= 0
        },
        "type"= "RollingUpdate"
      },
      "volume_claim_template"= [
        {
          "metadata"= {
            "name"= "data"
          },
          "spec"= {
            "access_modes"= [
              "ReadWriteOnce"
            ],
            "resources"= {
              "requests"= {
                "storage"= "1Gi"
              }
            }
          }
        }
      ]
    }
  }

  resource "null_resource" "routes" {
  provisioner "local-exec" {
    command = "oc create -f routes.yaml"
  }
}
