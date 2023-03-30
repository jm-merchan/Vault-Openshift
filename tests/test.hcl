global:
   enabled: true
   tlsDisable: false # Disabling TLS to avoid issues when connecting to Vault via port forwarding
   openshift: true
injector:
   enabled: true

# Supported log levels include: trace, debug, info, warn, error
logLevel: "trace"
server:
# config.yaml
   image:
      repository: registry.connect.redhat.com/hashicorp/vault-enterprise
      tag: 1.12.3-ent
   enterpriseLicense:
      secretName: vault-ent-license
   extraEnvironmentVars:
      VAULT_CACERT: /vault/userconfig/vault-ha-tls/vault.ca
      VAULT_TLSCERT: /vault/userconfig/vault-ha-tls/vault.crt
      VAULT_TLSKEY: /vault/userconfig/vault-ha-tls/vault.key
      VAULT_SKIP_VERIFY: false
      # https://support.hashicorp.com/hc/en-us/articles/8552873602451-Vault-on-Kubernetes-and-context-deadline-exceeded-errors
      VAULT_CLIENT_TIMEOUT: "300s"
   volumes:
      - name: userconfig-vault-ha-tls
        secret:
         defaultMode: 420
         secretName: vault-ha-tls
   volumeMounts:
      - mountPath: /vault/userconfig/vault-ha-tls
        name: userconfig-vault-ha-tls
        readOnly: true
   standalone:
      enabled: false
   affinity: ""
   logLevel: "trace"
   ha:
      enabled: true
      replicas: 3
      raft:
         enabled: true
         setNodeId: true
         config: |
            ui = true
            listener "tcp" {
               tls_disable = 0 # Disabling TLS to avoid issues when connecting to Vault via port forwarding
               address = "[::]:8200"
               cluster_address = "[::]:8201"
               tls_cert_file = "/vault/userconfig/vault-ha-tls/vault.crt"
               tls_key_file  = "/vault/userconfig/vault-ha-tls/vault.key"
               tls_client_ca_file = "/vault/userconfig/vault-ha-tls/vault.ca"
               api_address = "https://vault-active.vault.svc.cluster.local:8200"
               tls_require_and_verify_client_cert = false
               tls_disable_client_certs           = true
            }
            storage "raft" {
               path = "/vault/data"

               retry_join {
                  auto_join             = "provider=k8s namespace=vault label_selector=\"component=server,app.kubernetes.io/name=vault\""
                  auto_join_scheme      = "https"
                  leader_ca_cert_file   = "/vault/userconfig/vault-ha-tls/vault.ca"
                  leader_tls_servername = "vault-0.vault-internal"
               }
            }
            disable_mlock = true
            service_registration "kubernetes" {}