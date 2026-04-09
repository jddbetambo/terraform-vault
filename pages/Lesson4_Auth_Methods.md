# Authentication Methods

Authentication in Vault is the process by which user or machine supplied information is verified against an internal or external system. Vault supports multiple auth methods including GitHub, LDAP, AppRole, and more. Each auth method has a specific use case.

Before a client can interact with Vault, it must authenticate against an auth method. Upon authentication, a token is generated. This token is conceptually similar to a session ID on a website. The token may have attached policy, which is mapped at authentication time. This process is described in detail in the policies concepts documentation.

Auth methods are the components in Vault that perform authentication and are responsible for assigning identity and a set of policies to a user. In all cases, Vault will enforce authentication as part of the request processing. In most cases, Vault will delegate the authentication administration and decision to the relevant configured external auth method **(e.g., Amazon Web Services, GitHub, Google Cloud Platform, Kubernetes, Microsoft Azure, Okta ...)**.

Having multiple auth methods enables you to use an auth method that makes the most sense for your use case of Vault and your organization.


# 1.Vault Auth Methods enabling using CLI

## 1.1 Configuring Auth Methods using CLI

```bash
vault auth <command>
```
`<command>` can be:

- **`enable`** - enable a new auth method
- **`disable`** - desable a auth method (the name ot he mount we want to disable not the type of the auth method)
- **`list`** - list enabled auth methods 
- **`tune`** - used to modify an auth method
- **`help`** - show information how to use vault auth commande

```bash
# Enables the auth method approle at the default path
vault auth enable <auth-method> 
```
```bash
# Enables the auth method approle at a custom path vault-course
vault auth enable -path=vault-course <auth-method> 
```
```bash
# List enabled auth methods
vault auth list 
vault read sys/auth
```
```bash
# Disables the auth method approle at a custom path vault-course
vault auth disable <aut-method|vault-course>  
```

## 1.2 Userpass Auth Method using CLI

### 1.2.1 Enabling Userpass Auth Method using CLI

**1. Enable an Auth Method userpass on the path jdtech**

```bash
vault auth enable -path=jdtech -description="Local credentials for Vault" userpass
```

**2. Create a user John and assign a password and policies on the auth method jdtech**

```bash
vault write auth/jdtech/users/john password=vault policies=vault-policy
```

**3. List the enabled auth methods on Vault server**

```bash
vault auth list
```

**4. List the users under the path jdtech**

```bash
vault list auth/jdtech/users
```

**5. Read/show the information related to the user john**
```bash
vault read auth/jdtech/users/john
```

### 1.2.2 Authentication with Userpass Auth Method using CLI

```bash
# Used to obtain a token
vault login -method=userpass username=john 
```

## 1.3 Enabling Approle Auth Method using CLI

### 1.3.1 Enabling Approle Auth Method using CLI

**1. Enable an Auth Method approle on the path jdcloud**

```bash
vault auth enable -path=jdcloud -description="Roles for Vault" approle
```

**2. Create a role myrole**

- Creating a role without a policy

```bash
vault write -f auth/jdcloud/role/myrole 
```

- Creating a role with a policy

```bash
vault write auth/jdcloud/role/myrole \
    policies=test-policy \
    token_ttl=20m
```

**4. List the roles under the path jdcloud**

```bash
vault list auth/jdcloud/role
```

**5. Read/show the information related to the role myrole**

```bash
vault read auth/jdcloud/role/myrole
```

### 1.3.2 Authentication with Approle Auth Method using CLI**

When the **approle** auth method is already enabled and the role **john** is already created.

**1. Get the `role-id`**

```bash
vault read auth/jdcloud/role/myrole/role-id
```

**2. Create the `secret-id`**

```bash
vault write -force auth/jdcloud/role/myrole/secret-id
```

**3. Create a login authentication**

```bash
vault write auth/jdcloud/login \
    role_id=<role-id> \
    secret_id=<secret-id>
```

# 2. Vault Auth configuration using API

## 2.2 Userpass Auth Method using API

**0. Set these environment variables first (example)**

```bash
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="s.your_admin_token"
```

**1. Enable the userpass auth method**

Enable mount at auth/userpass (path can be different if you choose):

```bash
curl --header "X-Vault-Token: $VAULT_TOKEN" \
     --request POST \
     --data '{"type":"userpass","description":"username/password auth"}' \
     $VAULT_ADDR/v1/sys/auth/userpass
```

Or using a json file called my_file1.json

```bash
{
  "type": "userpass",
  "description": "username/password auth"
}
```

```bash
curl --header "X-Vault-Token: $VAULT_TOKEN" \
     --request POST \
     --data @my_file.json.json \
     $VAULT_ADDR/v1/sys/auth/userpass
```

**2. Create a user with assigned policies**

```bash
curl --header "X-Vault-Token: $VAULT_TOKEN" \
     --request POST \
     --data '{
       "password": "alice-password",
       "policies": "default,cloud-policy",
       "ttl": "1h",
       "max_ttl": "24h",
       "display_name": "Alice Example",
       "disabled": false
     }' \
     $VAULT_ADDR/v1/auth/userpass/users/alice
```

Or using a json file called my_file2.json

```bash
{
  "password": "alice-password",
  "policies": "default,cloud-policy",
  "ttl": "1h",
  "max_ttl": "24h",
  "display_name": "Alice Example",
  "disabled": false
}
```
```bash
curl \
  --header "X-Vault-Token: $VAULT_TOKEN" \
  --request POST \
  --data @my_file2.json \
  $VAULT_ADDR/v1/auth/userpass/users/alice
```

**3. Update an existing user**

To change password, policies, or metadata, call the same endpoint again with updated fields:

```bash
curl --header "X-Vault-Token: $VAULT_TOKEN" \
     --request POST \
     --data '{"password":"new-password","policies":"default,ops-policy"}' \
     $VAULT_ADDR/v1/auth/userpass/users/alice
```

**4. Read user information (metadata)**
To read stored user metadata (note: password is not returned):

```bash
curl --header "X-Vault-Token: $VAULT_TOKEN" \
     $VAULT_ADDR/v1/auth/userpass/users/alice | jq .
```
Returned JSON includes policies, display_name, ttl, max_ttl, and disabled status.

**5. Delete a user**
Remove the user account:

```bash
curl --header "X-Vault-Token: $VAULT_TOKEN" \
     --request DELETE \
     $VAULT_ADDR/v1/auth/userpass/users/alice
```

**6. User login (authenticate) via userpass**
A client authenticates by posting username/password to get a Vault token:

```bash
curl --request POST \
     --data '{"password":"alice-password"}' \
     $VAULT_ADDR/v1/auth/userpass/login/alice | jq .
```

**7. List all users**
There is an endpoint to list the usernames under the userpass mount:

```bash
curl --header "X-Vault-Token: $VAULT_TOKEN" \
     $VAULT_ADDR/v1/auth/userpass/users?list=true | jq .
```
If successful, .data.keys contains usernames. Note: Requires policy allowing list on auth/userpass/users.

**8. Enable userpass at a custom path or with options**
To enable at a custom mount path (e.g., auth/my-userpass) or set mount options, use sys/auth POST specifying path:

```bash
curl --header "X-Vault-Token: $VAULT_TOKEN" \
     --request POST \
     --data '{"type":"userpass","path":"my-userpass","description":"custom mount"}' \
     $VAULT_ADDR/v1/sys/auth
```
Operations then use /v1/auth/my-userpass/... endpoints.

**9. Configure mount-level settings (e.g., listing, token options)**
You can tune mount options with sys/mounts/<path>/tune:

```bash
curl --header "X-Vault-Token: $VAULT_TOKEN" \
     --request POST \
     --data '{"default_lease_ttl":"1h","max_lease_ttl":"24h"}' \
     $VAULT_ADDR/v1/sys/mounts/auth/userpass/tune
```

**10. Disable userpass auth method**
To remove the mount entirely:

```bash
curl --header "X-Vault-Token: $VAULT_TOKEN" \
     --request DELETE \
     $VAULT_ADDR/v1/sys/auth/userpass
```
This deletes all users under that mount. Use with caution.

**11. Example: Create a user and login (full sequence)**

```bash
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="s.AdminToken"

# Enable userpass
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
     --request POST --data '{"type":"userpass"}' \
     $VAULT_ADDR/v1/sys/auth/userpass

# Create user bob
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
     --request POST \
     --data '{"password":"bob-secret","policies":"default,dev-policy"}' \
     $VAULT_ADDR/v1/auth/userpass/users/bob

# Login as bob (get token)
curl -s --request POST --data '{"password":"bob-secret"}' \
     $VAULT_ADDR/v1/auth/userpass/login/bob | jq .
```

**12. Permissions required to manage userpass via API**
The admin token (or calling token) must have policy capabilities:

- sys/auth (create/delete) to enable/disable auth methods.
- sys/mounts/*/tune to tune mount.
- auth/userpass/users/* create/read/update/delete/list to manage users.
- auth/userpass/login/* is public for login (no token required), but some mounts may restrict login behavior.

Example minimal admin policy (not exhaustive):

```bash
path "sys/auth/*" {
  capabilities = ["create","read","update","delete","list"]
}
path "auth/userpass/*" {
  capabilities = ["create","read","update","delete","list"]
}
path "sys/mounts/*/tune" {
  capabilities = ["update"]
}
```

# 2.3 AppRole Auth Method using API

- **Create an `auth.json` file:**

```bash
{
  "type": "approle"
}
```

- **Use `curl` to enable AppRole:**

```bash
curl --header "X-Vault-Token: $VAULT_TOKEN" \
     --request POST \
     --data @auth.json \
     http://127.0.0.1:8200/v1/sys/auth/approle
```

- **Verify the mount:**

```bash
vault auth list
```

You should see an entry for `approle/`.

### Create an AppRole with Policies

- **Define which policies this AppRole will use `policies.json`:**

```bash
{
  "policies": ["bryan"]
}
```

- **Create the AppRole named `vaultcourse`:**

```bash
curl --header "X-Vault-Token: $VAULT_TOKEN" \
     --request POST \
     --data @policies.json \
     http://127.0.0.1:8200/v1/auth/approle/role/vaultcourse
```

A successful response confirms the role is created.

### Fetch the Role ID

**Each AppRole has a unique `Role ID`. Retrieve it:**

```bash
curl --header "X-Vault-Token: $VAULT_TOKEN" \
     http://127.0.0.1:8200/v1/auth/approle/role/vaultcourse/role-id | jq
```

**Inspect `data.role_id` in the JSON response.**

## Generate a Secret ID

**Generate the `Secret ID` needed alongside the `Role ID`:**

```bash
curl --header "X-Vault-Token: $VAULT_TOKEN" \
     --request POST \
     http://127.0.0.1:8200/v1/auth/approle/role/vaultcourse/secret-id | jq
```

The response returns:

- `data.secret_id`
- `data.secret_id_accessor`

**With these credentials, you can log in:**

```bash
curl --request POST \
     --data '{"role_id":"<ROLE_ID>","secret_id":"<SECRET_ID>"}' \
     http://127.0.0.1:8200/v1/auth/approle/login
```


# 3. Vault Entities

- An **Entity** is a representation of a single person or system used to log into Vault. Each has a unique value. Each **entity** is made up of zero or more **aliases**.
- **Alias** is a combinaison of the aut method plus some identification. It is a mapping between an **entity** and **auth method(s)**
- Vault create an **entity** and attaches an alias to it if a correponding entity doesn't already exist. This is done using the **identity secrets engine**, which manages internal identities that are recognized by Vault.

**Scenario 1**

<p>
    <img src="../images/entities.png">
</p>

- Julie is a user, a Finance Specialist
- She can log into Vault using userpass auth method
- When she has connected an Entity has been create made of the auth method and the username jsmith
- There are also some metadata to describe Julie and some policies

**Scenario 2**

In this scenario if Julie logs in using LDAP, the token that she gets is bound with finance policies. If she want to gather some information in accounts payable, she needs to log out from Vault from the LDAP and then log in with Github auth method.This is not efficient.

**Scenario 3**

Consolidating Logins under a Single Entity

- An entity can be **manually created** to map multiple entities for a single user to provide more efficient authorization managament
- Any tokens that are created for the entity **inherit the capabilities** that are granted by alias(es)

# Documentation

- [Auth methods](https://developer.hashicorp.com/vault/docs/auth)
- [AWS auth method](https://developer.hashicorp.com/vault/docs/auth/aws)
- [Okta auth method](https://developer.hashicorp.com/vault/docs/auth/okta)
- [Kubernetes auth method](https://developer.hashicorp.com/vault/docs/auth/kubernetes)
- [Vault Identity](https://developer.hashicorp.com/vault/tutorials/auth-methods/identity)
- [How to Configure Vault Authentication Methods](https://oneuptime.com/blog/post/2026-02-02-vault-auth-methods/view)
- [A Guide to securing your applications secrets with vault authentication](https://medium.com/@timzowen/a-guide-to-securing-your-applications-secrets-with-vault-authentication-4d23bc2a55ab)


# Next

[Lesson 5: Vault Policy](Lesson5_Policy.md)
