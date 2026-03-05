<p>
    <img src="../images/vso1.png">
</p>

# Vault Secrets Operator - Overview

The Vault Secrets Operator (VSO) allows Pods to consume Vault secrets natively from Kubernetes Secrets. The Vault Secrets Operator (VSO) is a fully supported component of HashiCorp Vault.

- A kubernetes-native controller that syncs secrets from Vault to Kubernetes (one-way-sync)
- Rather than have pods go directly to Vault, they can read secrets natively from Kubernetes secrets
- Designed to make Vault secrets first-class citizen in Kubernetes

The Vault Secrets Operator operates by watching for changes to its supported set of Custom Resource Definitions (CRD). Each CRD provides the specification required to allow the operator to synchronize from one of the supported sources for secrets to a Kubernetes Secret. The operator writes the source secret data directly to the destination Kubernetes Secret, ensuring that any changes made to the source are replicated to the destination over its lifetime. In this way, an application only needs to have access to the destination secret in order to make use of the secret data contained within.

# Vault Secrets Operator vs Vault Agent

<p>
    <img src="../images/vso2.png">
</p>

The Vault Secrets Operator (VSO) and the Vault Agent Injector are two popular methods for managing secrets in Kubernetes workloads. Both tools have their place, and some teams may use both depending on the use case. The choice should help your team move fast without sacrificing security or sanity. There are different methods for integrating Vault with Kubernetes.

- most teams choose between the Vault Agent Injector and the Vault Secret Operator for Kubernetes integration
- VSO it he newer option and is gaining popularity with teams using GitOps and declarative infrastructure models. Here's a comparison of their key features:

### Vault Secrets Operator (VSO)

Installs a controller in your cluster that uses Kubernetes-native CRDs to sync Vault secrets directly into Kubernetes Secrets. Applications read from a native Kubernetes secret, no Vault logic inside the pod. Ideal for GitOps workflows and managing multiple apps across teams and namespaces. 

**Capabilities**
- If you prefer a simple, more declarative approach that integrates easily with GitOps or CI/CD pipelines, the Vault Secrets Operator might be the better fit.
- It works best when you want secrets to feel native to Kubernetes
- You prefer using native Kubernetes Secrets or your applications require it
- You are manaing many apps across teams with centralized sunc logic

### Vault Agent Injector 

Works with a sidecar pattern, modifying your pod spec to inject a Vault Agent container alongside your application. It's simple and reliable for apps needing file-based secrets or tight control over template rendering and secret renewal. However, it adds complexity with sidecars, webhooks, and extra management. 

**Capabilities**
- This method is a srog fit when you need tight control over how and when secrets are injected.
- Choose it when your app or environment demands file-based secrets, renewal control, or runtime flexibility
- Your app requires secrets as files (e.g. TLS Certs)
- You want runtime secret injection per pod lifecycle
- You prefer a sidecar âttern for tighter control
- You need fine-gained renewal control or template rendering

### Comparative table

<table>
<tbody>
<tr>
<td><strong>Feature</strong></td>
<td>
<p><b>Vault Agent Injector</b></p>
</td>
<td>
<p><b>Vault Secrets Operator</b></p>
</td>
<td></td>
</tr>
<tr>
<td><b>Secret delivery</b></td>
<td><span style="font-weight: 400;">Sidecar volume</span></td>
<td><span style="font-weight: 400;">Kubernetes Secret</span></td>
<td></td>
</tr>
<tr>
<td><b>Dynamic secrets support</b></td>
<td><span style="font-weight: 400;">✅ Yes</span></td>
<td><span style="font-weight: 400;">❌ No (manual rotation)</span></td>
<td></td>
</tr>
<tr>
<td><b>Lease management</b></td>
<td><span style="font-weight: 400;">✅ Automatic</span></td>
<td><span style="font-weight: 400;">❌ No</span></td>
<td></td>
</tr>
<tr>
<td><b>GitOps-compatibility</b></td>
<td><span style="font-weight: 400;">⚠️ Limited (via annotations)</span></td>
<td><span style="font-weight: 400;">✅ Full (via CRDs)</span></td>
<td></td>
</tr>
<tr>
<td><b>Use of native K8s secrets</b></td>
<td><span style="font-weight: 400;">❌ No</span></td>
<td><span style="font-weight: 400;">✅ Yes</span></td>
<td></td>
</tr>
<tr>
<td><b>Dependency on Vault at pod startup</b></td>
<td><span style="font-weight: 400;">✅ Yes</span></td>
<td><span style="font-weight: 400;">❌ No</span></td>
<td></td>
</tr>
<tr>
<td><b>Best application</b></td>
<td><span style="font-weight: 400;">Dynamic credentials</span></td>
<td><span style="font-weight: 400;">Static configuration</span></td>
<td></td>
</tr>
</tbody>
</table>

# Vault Secret - `Custom Resource Definition`

The Vault Secrets Custom Resource Definition (CRD) is a crucial component for managing secrets within Kubernetes environments. It allows for the creation and management of Kubernetes secrets from HashiCorp Vault, ensuring that secrets are securely stored and accessible within the cluster. 

The Vault Secrets Operator (VSO) is a key player in this process, as it synchronizes Vault secrets with Kubernetes Secrets, providing a seamless integration between the two systems. The VSO supports various features, including automatic secret drift and remediation, secret rotation for specific Kubernetes resource types, and the ability to transform secret data as needed. This integration simplifies the management of secrets for applications running on Kubernetes, ensuring that they can access the necessary data without the need for manual intervention.

In order to sync secrets and Kubernetes, the Vault Secrets Operator uses the Custom resource Deinition (CRD). They are going to describe what kind of secrets you want and where to get them in Vault.

There are 03 main types of CRDs used to sync your secrets

1. **Vault Static Secret** 

This CRD defines how the operator syncs a single static secret (KV Secret engine) from Vault to Kubernetes Secret.

```bash
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: my-static-secret
  namespace: web-app-ns
spec:
  vaultAuthRef: vault-auth
  mount: kv
  path: secret/data/my-static-secret
  type: kv-v2
  destination:
    create: true
    name: my-k8-secret
  refreshafter: 1h
```

2. **Vault Dynamc Secret**

This CRD syncs a dynmic Vault secret (Database Secret Engine) generated On demand to a Kubernetes Secret.

```bash
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultDynamicSecret
metadata:
  name: my-dynamic-secret
  namespace: ecommerce-app-ns
spec:
  vaultAuthRef: vault-auth
  mount: database
  path: creds/my-db-role
  destination:
    create: true
    name: my-dynamic-db-secret
  refreshafter: 30m
  fields:
    username: db-username
    password: db-password
```

3. **Vault KPI Secret**

This CRD configures the operator to generate a certificate using the PKI Secret Engine and sync it to a Kubernetes Secret.

```bash
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultPKISecret
metadata:
  name: my-pki-certificate
spec:
  vaultAuthRef: vault-auth
  mount: pki
  role: my-pki-role
  commonName: myapp.example.com
  destination:
    create: true
    name: my-pki-secret
  ttl: 24h
```

# Vault Secret Operator - Features

- **`Instant updates`**: Secrets update automatically when they change in Vault, no rstart required. This enables to stay in sync with real-time updates triggered by changes in Vault.
- **`Encrypted Client Cache`**: Secrets are stored securely in-memory with encryption. This reduces API calls and speeds up access while keeping data protected.
- **`Secret Transformation`**: Customize how secrets are formatted before reaching Kubernetes. This enables to rename keys; filter values or reschape data to match app needs.

# Documentation

- [Vault Agent Injector vs Secrets Operators](https://www.flowfactor.be/blogs/vault-agent-injector-vs-secrets-operator-kubernetes-comparison/)
- [Vault Agent Injector vs Secrets Operator](https://krausen.io/blog/vault-agent-injector-vs-vault-secrets-operator/)
- [Manage Kubernetes native secrets with the Vault Secrets Operator](https://developer.hashicorp.com/vault/tutorials/kubernetes-introduction/vault-secrets-operator)