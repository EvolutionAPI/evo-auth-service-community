# Extension Points

**Contract version:** `1.0.0` (SemVer)

This document is the public contract between `evo-auth-service-community`
and any external consumer that wants to plug into authentication without
forking or patching community source. The authoritative architectural
decision behind this contract is **ADR13 — Extension Points Versioning
Strategy**; the rules below are self-contained.

The community release is fully usable on its own. Every extension point
ships with a working default that delegates to the in-tree Devise /
devise_token_auth stack; a consumer can **replace** the default
implementation of one or more of them without modifying files in `app/`,
`lib/` or `db/`.

If you are about to change any of the three extension points below, read
the [Compatibility Promise](#compatibility-promise) first.

---

## Compatibility Promise

Each extension point is versioned independently and treated as a public
API, with the same backward-compatibility rules as the REST endpoints
exposed by this service:

- **Backward compatibility is forever.** Once shipped at a given major,
  the name, arguments, return shape and observable behavior of an
  extension point do not change silently.
- **Breaking changes require a major bump** of the affected extension
  point and of the community release that ships it.
- **Deprecation window is at least one minor release.** The old shape
  keeps working alongside the new one, and the deprecated path emits a
  warning via `Rails.logger`.
- **Additive changes are minor bumps.** New extension point, or new
  optional capability on an existing one.
- **Bug fixes that preserve the contract are patch bumps.**

Bumping one extension point does not bump the others.

---

## Extension points

All three are exposed under the `EvoExtensionPoints` namespace,
implemented by `lib/evo_extension_points/` (shipped in a complementary
story). The aggregate contract version is exposed at
`EvoExtensionPoints::EXTENSION_POINTS_VERSION`.

### 1. `auth_bridge`

**Version:** `1.0.0`
**Default:** delegates to the in-tree Devise / devise_token_auth stack;
`current_user` returns the user resolved by `devise_token_auth` from the
current request, or `nil` outside a request scope.

```ruby
EvoExtensionPoints::AuthBridge.create_user(email:, password:, attrs: {}) # => User
EvoExtensionPoints::AuthBridge.sign_in_user(user)                        # => user signed in for the current request
EvoExtensionPoints::AuthBridge.current_user                              # => User | nil
EvoExtensionPoints::AuthBridge.sign_out(user)                            # => user signed out
```

Override:

```ruby
EvoExtensionPoints.replace(:auth_bridge_create_user) do |email:, password:, attrs: {}|
  MyConsumer::Accounts.create_user(email: email, password: password, attrs: attrs)
end

EvoExtensionPoints.replace(:auth_bridge_sign_in_user)  { |user| MyConsumer::Sessions.sign_in(user) }
EvoExtensionPoints.replace(:auth_bridge_current_user)  { MyConsumer::Current.user }
EvoExtensionPoints.replace(:auth_bridge_sign_out)      { |user| MyConsumer::Sessions.sign_out(user) }
```

**Breaking-change policy:** renaming `create_user`, `sign_in_user`,
`current_user` or `sign_out`, changing required keyword arguments, or
changing the return type of `current_user` from `User | nil` is a major
bump. Adding an optional keyword argument to `create_user` or sibling
helpers is a minor bump.

### 2. `token_claims`

**Version:** `1.0.0`
**Default:** returns an empty hash; the community release adds no extra
claims beyond what devise_token_auth already emits.

```ruby
EvoExtensionPoints::TokenClaims.claims_for(user) # => Hash<String, Object>
```

Override:

```ruby
EvoExtensionPoints.replace(:token_claims) do |user|
  MyConsumer::Claims.for(user) # e.g. { "audience" => "my_consumer", "roles" => user.role_names }
end
```

The returned hash is merged into the token payload by the auth-service
at emission time. Keys reserved by the JWT spec (`iss`, `sub`, `aud`,
`exp`, `iat`, `nbf`, `jti`) MUST NOT be overwritten by a consumer; the
auth-service drops conflicting keys and emits a warning.

**Breaking-change policy:** renaming `claims_for`, changing the return
type from `Hash`, or silently overwriting reserved JWT keys is a major
bump. Adding new optional behavior on top of the merge is a minor bump.

### 3. `login_gate`

**Version:** `1.0.0`
**Default:** always returns `:allow`; the community release performs no
pre-login check beyond what Devise already enforces (confirmed,
not-locked, valid credentials).

```ruby
EvoExtensionPoints::LoginGate.check(user, **context) # => :allow | [:deny, reason]
```

`context` carries neutral request-derived data (e.g. `ip:`,
`user_agent:`) that the consumer may use to decide. The auth-service
treats any return value other than `:allow` as a denial; when the value
is `[:deny, reason]`, `reason` is a short symbol the consumer chooses
(e.g. `:rate_limited`, `:not_active`) and is surfaced in the audit log
without being shown to the end user.

Override:

```ruby
EvoExtensionPoints.replace(:login_gate) do |user, **context|
  MyConsumer::Access.check(user, **context)
end
```

**Breaking-change policy:** renaming `check`, changing the accepted
return shape, or changing the semantics of `:allow` is a major bump.
Adding new accepted keys in `context` or new accepted denial reasons is
a minor bump.

---

## How to use as a consumer

A consumer wires its replacements once, from a `Railtie` or `Engine`
initializer, and never patches files inside `evo-auth-service-community`:

```ruby
require "evo_extension_points"

module MyConsumer
  class Railtie < ::Rails::Railtie
    initializer "my_consumer.auth_extension_points" do
      EvoExtensionPoints.replace(:auth_bridge_create_user) do |email:, password:, attrs: {}|
        MyConsumer::Accounts.create_user(email: email, password: password, attrs: attrs)
      end

      EvoExtensionPoints.replace(:auth_bridge_current_user) { MyConsumer::Current.user }

      EvoExtensionPoints.replace(:token_claims) do |user|
        { "audience" => "my_consumer", "roles" => user.role_names }
      end

      EvoExtensionPoints.replace(:login_gate) do |user, **context|
        MyConsumer::Access.check(user, **context)
      end
    end
  end
end
```

A consumer is expected to declare the community version range it
supports in its own package metadata (gemspec). A CI workflow
(`extension-points-contract`) runs a neutral consumer stub against every
community PR, failing the build on a contract break.

---

## Cross-references

- Companion contract on the CRM side:
  [evo-ai-crm-community/EXTENSION_POINTS.md](https://github.com/evolution-foundation/evo-ai-crm-community/blob/main/EXTENSION_POINTS.md).
- Companion contract on the Python processor side:
  [evo-ai-processor-community/EXTENSION_POINTS.md](https://github.com/evolution-foundation/evo-ai-processor-community/blob/main/EXTENSION_POINTS.md).
- The architectural decision that motivates this contract is **ADR13 —
  Extension Points Versioning Strategy**.

---

## Versioning history

- `1.0.0` — Initial contract: `AuthBridge`, `TokenClaims`, `LoginGate`.
