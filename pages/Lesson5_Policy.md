# 1. Overview on Vault Policies

Everything in Vault is path-based, and policies are no exception. Policies provide a declarative way to grant or forbid access to certain paths and operations in Vault. This section discusses policy workflows and syntaxes.

- Provide operator a way to **permit or deny access** to certain paths or actions within Vault (RABC)
- Gives us the ability to **provide granular control** over who gets access to secrets
- Policies are written in **declarative statements** and can be written using **JSON** or **HCL**
- When writting policies, always follow the **principle of least privilege**: give users/applications only permissions they need
- Policies are denied by default (implicit deny), therefore you musy explicitly grant to paths and related capabilities to Vault clients
- Policies are attached to a token. A token can have multiple policies. Policies are cumulative and capabilities are additive
- **Root policy** is created by default: **Superuser** with all permission. 
    - You **cannot** change or delete this policy
    - It is attached to all root tokens
- **Default policy** is created by default: provide common permissions 
    - You **can** change but it cannot be deleted
    - Attached to all non-root tokens by default (can be removed if needed)

# 2. Policy-authorization workflow

<p>
    <img src="../images/policy2.png">
</p>

1. A user attempts to authenticate to Vault using their LDAP credentials, providing Vault with their LDAP username and password.
2. Vault establishes a connection to LDAP and asks the LDAP server to verify the given credentials. Assuming this is successful, the LDAP server returns the information about the user, including the OU groups.
3. Vault maps the result from the LDAP server to policies inside Vault using the mapping configured by the security team in the previous section. Vault then generates a token and attaches the matching policies.
4. Vault returns the token to the user. This token has the correct policies assigned, as dictated by the mapping configuration that was setup by the security team in advance.

The user then uses this Vault token for future operations. If the user performs the authentication steps again, they will get a **new token**. The token will have the same permissions, but the **actual token will be different**. Authenticating a second time does not invalidate the original token.

# 3. Managing Vault Policies
## 3.1 Vault Policy Commands

```bash
vault policy <command>
```
`<command>` can be:

- `delete`: deletes a policy by name
- `fmt`: Formats a policy on disk
- `list` : Lists the installed policies
- `read`: Prints the contents of a policy
- `write`: Uploads (create) a named policy from a file

```bash
# Create a policy based on a file
vault policy write <policy_name> <policy_filename.hcl>
```
```bash
# Prints the contents of a policy
vault policy read <policy_name> 
```
```bash
# Lists the installed policies
vault policy list 
```
or
```bash
vault read sys/policy 
```
```bash
# Formats a policy on disk
vault policy fmt <policy_filename.hcl> 
```
```bash
# Delete a policy
vault policy delete <policy_name> 
```

## 3.2 Policy Capabilities

Each path must define one or more capabilities which provide fine-grained control over permitted (or denied) operations. 

**The list of capabilities include the following with the associated HTTP verbs in parenthesis :**

- `create` (`POST/PUT`) - Allows creating data at the given path. 
- `read` (`GET`) - Allows reading the data at the given path.
- `update` (`POST/PUT`) - Allows changing the data at the given path. 
- `patch` (`PATCH`) - Allows partial updates to the data at a given path.
- `delete` (`DELETE`) - Allows deleting the data at the given path.
- `list` (`LIST`) - Allows listing values at the given path. 

**In addition to the standard set, there are some capabilities that do not map to HTTP verbs.**

- `sudo` - Allows access to paths that are root-protected. 
- `deny` - Disallows access, including sudo privilige.
- `subscribe` - Allows subscribing to events for the given path.
- `recover` - Allows recovering the data on the given path from a snapshot


## 3.3 Anatomy of a Vault policy

Policies are written in HCL or JSON and describe which paths in Vault a user or machine is allowed to access.

```bash
path "<path>" {
    capabilities = ["<list of permissions (capabilities)>"]
}
```

Here is a very simple policy which grants read capabilities to the **KVv1** path **secret/foo**:

```bash
path "secret/foo" {
  capabilities = ["read"]
}
```
When this policy is assigned to a token, the token can read from "secret/foo". However, the token cannot update or delete "secret/foo", since the capabilities do not allow it. Because policies are <span style="color:red">**deny by default**</span>, the token would have no other access in Vault.

Here is a more detailed policy, and it is documented inline:

```bash
# This section grants all access on "secret/*". further restrictions can be
# applied to this broad policy, as shown below.
path "secret/*" {
  capabilities = ["create", "read", "update", "patch", "delete", "list", "recover"]
}

# Even though we allowed secret/*, this line explicitly denies
# secret/super-secret. this takes precedence.
path "secret/super-secret" {
  capabilities = ["deny"]
}
```

## 3.4 Customizing the path

Policies use path-based matching to test the set of capabilities against a request. A policy path may specify an exact path to match, or it could specify a **glob** pattern which instructs Vault to use a prefix match:

```bash
# Permit reading only "secret/foo". an attached token cannot read "secret/food"
# or "secret/foo/bar".
path "secret/foo" {
  capabilities = ["read"]
}

# Permit reading everything under "secret/bar". An attached token could read
# "secret/bar/zip", "secret/bar/zip/zap", but not "secret/bars/zip".
path "secret/bar/*" {
  capabilities = ["read"]
}

# Permit reading everything prefixed with "zip-". an attached token could read
# "secret/zip-zap" or "secret/zip-zap/zong", but not "secret/zip/zap
path "secret/zip-*" {
  capabilities = ["read"]
}
```

In addition, a <span style="color:red">**+**</span> can be used to denote any number of characters bounded within a single path segment (this appeared in Vault 1.1):

```bash
# Permit reading the "teamb" path under any top-level path under secret/
path "secret/+/teamb" {
  capabilities = ["read"]
}

# Permit reading secret/foo/bar/teamb, secret/bar/foo/teamb, etc.
path "secret/+/+/teamb" {
  capabilities = ["read"]
}
```

Vault's architecture is similar to a filesystem. Every action in Vault has a corresponding path and capability - even Vault's internal core configuration endpoints live under the "sys/" path. Policies define access to these paths and capabilities, which controls a token's access to credentials in Vault.

## 3.5 Policy with Parameters

Vault policies control which paths and operations a principal (token/role) may perform. They do not directly validate arbitrary parameter names or values inside secret payloads — that validation is usually implemented by the secrets engine (roles, templates, or external checks) or by using Sentinel/OIDC/Enterprise features. However, you can use policies to allow or deny specific API endpoints and restrict which parameters can be set indirectly by restricting paths and capabilities. 

### Policy with Allowed Parameters

- This policy allows a client to generate AWS credentials only for specific IAM roles. - The caller may only request credentials for the two listed IAM roles. Any other **role_arn** is rejected.


```bash
path "aws/creds/*" {
  capabilities = ["read"]

  allowed_parameters = {
    "role_arn" = [
      "arn:aws:iam::123456789012:role/app-readonly",
      "arn:aws:iam::123456789012:role/app-admin"
    ]
  }
}
```

- In this policy, the key "secret/restricted" can only contain "foo" (any value) and "bar" (one of "zip" or "zap").

```bash
path "secret/restricted" {
  capabilities = ["create"]

  allowed_parameters = {
    "foo" = []
    "bar" = ["zip", "zap"]
  }
}
```

### Policy with Disallowed Parameters

This policy prevents users from requesting long-lived credentials by blocking certain TTL values. - The caller cannot request TTLs of 1h, 2h, or 24h. Any other TTL is allowed (unless restricted elsewhere).

```bash
path "aws/creds/*" {
  capabilities = ["read"]

  disallowed_parameters = {
    "ttl" = ["1h", "2h", "24h"]
  }
}
```

### Policy with Required Parameters

This policy forces the caller to include a specific parameter when generating credentials. The caller must include username_prefix="app-" in the request. If the parameter is missing or different, Vault rejects the request.

```bash
path "database/creds/app-role" {
  capabilities = ["read"]

  required_parameters = {
    "username_prefix" = ["app-"]
  }
}
```

### Combined Example (Allowed + Required + Disallowed)

Here’s a more advanced policy that uses all three. This is a very realistic PKI policy used in production.

- **Allowed**: TTL must be 1h, 2h, or 4h; key type must be RSA or EC
- **Required**: common_name must be provided
- **Disallowed**: wildcard SANs for internal domains are forbidden

``` bash
path "pki/issue/app-cert" {
  capabilities = ["create", "update"]

  allowed_parameters = {
    "ttl" = ["1h", "2h", "4h"]
    "key_type" = ["rsa", "ec"]
  }

  required_parameters = {
    "common_name" = []
  }

  disallowed_parameters = {
    "alt_names" = ["*.internal.local"]
  }
}
```

### KV Example (simple but useful)

Even KV v2 can use parameter restrictions:

- Must include a data object
- Cannot use CAS writes

``` bash
path "kv/data/app/*" {
  capabilities = ["create", "update"]

  required_parameters = {
    "data" = []
  }

  disallowed_parameters = {
    "options" = ["cas"]
  }
}
```

## 3.6 Templated policies

The policy syntax allows for doing variable replacement in some policy strings with values available to the token. Currently **identity** information can be injected, and currently the **path** keys in policies allow injection.

<table border="1">
<tr background="grey">
    <td><b>Name</b></td>
    <td><b>Description</b></td>
</tr>
<tr>
    <td>identity.entity.id</td>
    <td>The entity's ID</td>
</tr>
<tr>
    <td>identity.entity.name</td>
    <td>The entity's name</td>
</tr>
<tr>
    <td>identity.entity.metadata.<metadata key></td>
    <td>Metadata associated with the entity for the given key</td>
</tr>
<tr>
    <td>identity.entity.aliases.<mount accessor>.id</td>
    <td>Entity alias ID for the given mount</td>
</tr>
</table>

**Examples**

The following policy creates a section of the KVv2 Secret Engine to a specific user

```bash
path "secret/data/{{identity.entity.id}}/*" {
  capabilities = ["create", "update", "patch", "read", "delete"]
}

path "secret/metadata/{{identity.entity.id}}/*" {
  capabilities = ["list"]
}
```

If you wanted to create a shared section of KV that is associated with entities that are in a group.

**In the example below, the group ID maps a group and the path**

```bash
path "secret/data/groups/{{identity.groups.ids.fb036ebc-2f62-4124-9503-42aa7A869741.name}}/*" {
  capabilities = ["create", "update", "patch", "read", "delete"]
}

path "secret/metadata/groups/{{identity.groups.ids.fb036ebc-2f62-4124-9503-42aa7A869741.name}}/*" {
  capabilities = ["list"]
}
```

**Note**: 

When developing templated policies, use IDs wherever possible. Each ID is unique to the user, whereas names can change over time and can be reused. This ensures that if a given user or group name is changed, the policy will be mapped to the intended entity or group.

[Source: Vault Policies Docs](https://developer.hashicorp.com/vault/docs/concepts/policies)


# 4. Default policy vs Root Policy

## 4.1 Default Policy

The default policy is a built-in Vault policy that cannot be removed. By default, it is attached to all tokens, but may be explicitly excluded at token creation time by supporting authentication methods.

- **To view all permissions granted by the default policy on your Vault installation**

```bash
vault read sys/policy/default
```

- **To disable attachment of the default policy**

```bash
vault token create -no-default-policy
```

or via the API:

```bash
$ curl \
  --request POST \
  --header "X-Vault-Token: ..." \
  --data '{"no_default_policy": "true"}' \
  https://vault.hashicorp.rocks/v1/auth/token/create
```

## 4.2 Root policy

The root policy is a built-in Vault policy that cannot be modified or removed. Any user associated with this policy becomes a root user. A root user can do anything within Vault. As such, it is highly recommended that you revoke any root tokens before running Vault in production.

When a Vault server is first initialized, there always exists one root user. This user is used to do the initial configuration and setup of Vault. After configured, the initial root token should be revoked and more strictly controlled users and authentication should be used.

- **To revoke a root token**

```bash
vault token revoke "<token>"
```

or via the API:

```bash
curl \
  --request POST \
  --header "X-Vault-Token: ..." \
  --data '{"token": "<token>"}' \
  https://vault.hashicorp.rocks/v1/auth/token/revoke
```

# 5. Managing policies

Policies are authored (written) in your editor of choice. They can be authored in HCL or JSON, and the syntax is described in detail above. Once saved, policies must be uploaded to Vault before they can be used.

# 5.1 Listing policies
To list all registered policies in Vault:

```bash
vault read sys/policy
```

or via the API:

```bash
curl \
  --header "X-Vault-Token: ..." \
  https://vault.hashicorp.rocks/v1/sys/policy
```

## 5.2 Creating policies

Policies may be created (uploaded) via the CLI or via the API. To create a new policy in Vault:

```bash
vault policy write policy-name policy-file.hcl
```

or via the API:

```bash
curl \
  --request POST \
  --header "X-Vault-Token: ..." \
  --data '{"policy":"path \"...\" {...} "}' \
  https://vault.hashicorp.rocks/v1/sys/policy/policy-name
```

## 5.3 Updating policies

Existing policies may be updated to change permissions via the CLI or via the API. To update an existing policy in Vault, follow the same steps as creating a policy, but use an existing policy name:

```bash
vault write sys/policy/my-existing-policy policy=@updated-policy.json
```

or via the API:

```bash
curl \
  --request POST \
  --header "X-Vault-Token: ..." \
  --data '{"policy":"path \"...\" {...} "}' \
  https://vault.hashicorp.rocks/v1/sys/policy/my-existing-policy
```

## 5.4 Deleting policies

Existing policies may be deleted via the CLI or API. To delete a policy:

```bash
vault delete sys/policy/policy-name
```

or via the API:

```bash
curl \
  --request DELETE \
  --header "X-Vault-Token: ..." \
  https://vault.hashicorp.rocks/v1/sys/policy/policy-name
```

# 5.5 Associating policies

Vault can automatically associate a set of policies to a token based on an authorization. This configuration varies significantly between authentication backends. For simplicity, this example will use Vault's built-in userpass auth method.

A Vault administrator or someone from the security team would create the user in Vault with a list of associated policies:

```bash
vault write auth/userpass/users/sethvargo \
    password="s3cr3t!" \
    policies="dev-readonly,logs"
```
This creates an authentication mapping to the policy such that, when the user authenticates successfully to Vault, they will be given a token which has the list of policies attached.

The user wishing to authenticate would run

```bash
vault login -method="userpass" username="sethvargo"
Password (will be hidden): ...
```
If the provided information is correct, Vault will generate a token, assign the list of configured policies to the token, and return that token to the authenticated user.

# 5.6 Example of some admin policies

```bash
# Read system health check
path "sys/health"
{
  capabilities = ["read", "sudo"]
}

# Create and manage ACL policies broadly across Vault

# List existing policies
path "sys/policies/acl"
{
  capabilities = ["list"]
}

# Create and manage ACL policies
path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Enable and manage authentication methods broadly across Vault

# Manage auth methods broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*"
{
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth"
{
  capabilities = ["read"]
}

# Enable and manage the key/value secrets engine at `secret/` path

# List, create, update, and delete key/value secrets
path "secret/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secrets engines
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines.
path "sys/mounts"
{
  capabilities = ["read"]
}
EOF
```

# 6. Testing Policies

## Part 1: Creating Your First Policy

**1. Create a new file called readonly-policy.hcl**

```bash
# Allow read-only access to secrets in the 'secret' path
path "secret/data/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/*" {
  capabilities = ["list"]
} 
```

**2. Write this policy to Vault**

```bash
vault policy write readonly-policy readonly-policy.hcl
```

**3. Verify the policy was created**

```bash
vault policy list
```

```bash
vault policy read readonly-policy
```

## Part 2: Testing Policy Restrictions

**1. Create some test secrets**

```bash
# Create two test secrets
vault kv put secret/test-1 password="secret123"
vault kv put secret/test-2 api_key="abc123"
```

**2. Create a token with the readonly policy**

```bash
vault token create -policy=readonly-policy
```

**3. Login with the new generated token in another terminal**

```bash
vault token login <token>
```

**4. Test the policy restrictions**

- **These should work**

```bash
vault kv get secret/test-1
vault kv list secret/
```

- **These should not work**

```bash
vault kv put secret/test-3 password="newpass"
vault kv delete secret/test-1
```

## Part 3: Creating a More Complex Policy with Entity Templating

**1. Create the Policy**

Create a file called app-policy.hcl with the following contents:

```bash
# Allow management of app-specific secrets
path "secret/data/app/{{identity.entity.name}}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Allow listing of secret mount
path "secret/metadata/*" {
  capabilities = ["list"]
}
```

**2. Then, write the policy**

```bash
vault policy write app-policy app-policy.hcl
```

**3. Enable and Configure the Userpass Auth Method**

```bash
vault auth enable userpass
```

**4. Get the Userpass Accessor and set to a variable**

```bash
USERPASS_ACCESSOR=$(vault auth list -format=json | jq -r '."userpass/".accessor')
```

**5. Create an entity used to map the user to the policy**

```bash
vault write identity/entity name="app1" policies="app-policy"
```

Note the entity ID in the output.

**6. Create the Entity Alias for the Userpass user**

```bash
vault write identity/entity-alias \
    name="app1" \
    mount_accessor="$USERPASS_ACCESSOR" \
    canonical_id="<add_entity_id_here>"
```

Use the entity ID from the previous step in this command.

**7. Create the Userpass User**

```bash
vault write auth/userpass/users/app1 \
    password="password123"
```

**8. Test Login and Permissions using the Templated Policy**

```bash
# Login as the user
vault login -method=userpass \
    username=app1 \
    password=password123

# These should succeed
vault kv put secret/app/app1/config api_key="test123"
vault kv get secret/app/app1/config

# These should fail with 403
vault kv put secret/app/other-app/config api_key="test123"
vault kv put secret/test-3 password="newpass"
```

# 7. Administrative Policies

- Permissions for Vault backend functions live at the **sys/** path
- Users/admins will need policies that define what they can do within Vault to administer Vault itself
    - Unsealing
    - Changing policies
    - Adding secret backends
    - Configuring database configurations


# Next

[Lesson 6: Vault Token](Lesson6_Token.md)
