# zonemta-wildduck

WildDuck MSA plugin for [ZoneMTA](https://github.com/zone-eu/zone-mta). Install this to send as a user of the WildDuck IMAP server. This plugin handles authentication and header rewriting – users are only allowed to send mail from their registered email addresses. If the address in an email does not match then it is overridden with an allowed address. This is similar to the behavior of Gmail SMTP.

WildDuck actions apply only to interfaces that require authentication.

## Features

* **authentication** – if authentication is enabled for the smtp interface then authentication data is checked against WildDuck user accounts
* **From rewriting** – if the message has a From: address in the header that is not registered as one of the aliases for this user then the address part (but not the name) is rewritten with the default address for this user
* **Upload to Sent Mail folder** – sent message is automatically appended to the _Sent Mail_ folder of the user
* **Recipient limiting** – limit RCPT TO calls for 24 hour period based on the _recipients_ user value
* **Local delivery** – messages that are deliverable to the current WildDuck installation are routed directly to LMTP bypassing MX steps
* **Hybrid mail setup support** – optional local delivery bypass prevents mail loops when using external MX (e.g., Google Workspace) with catch-all forwarding back to your server

## Setup

Add this as a dependency of your ZoneMTA app:

```sh
npm install @zone-eu/zonemta-wildduck --save
```

Add a configuration entry in the "plugins" section of your ZoneMTA app

First enable authentication for the SMTP interface

```toml
# interfaces.toml
[feeder]
authentication=true
port=587
```

Then set up configuration for this plugin, see the [example config](./config.example.toml) file for details.

## Hybrid Mail Setup (e.g., Google Workspace)

If you use an external mail service (like Google Workspace) as your primary MX but also want to host some addresses locally in WildDuck, you may encounter delivery issues:

1. ZoneMTA sends email to `user@example.com`
2. MX lookup returns Google's servers
3. Google receives the email but the address doesn't exist there (or routing is delayed)
4. Google's catch-all forwards it back to your server
5. **Potential mail loop** — delivery may fail or be delayed

This doesn't always fail, but it's unreliable and can cause mail to bounce unexpectedly.

### The Solution

Enable the `localDelivery` option. This tells ZoneMTA to check if a recipient exists in WildDuck **before** looking up the MX. If found, it **overrides the MX routing** and delivers directly to your internal mail server instead of sending to the external MX.

```toml
["modules/@zone-eu/zonemta-wildduck".localDelivery]
enabled = true
domains = ["example.com"]
deliveryZone = "local" # Existing ZoneMTA zone configured for internal delivery
```

If no dedicated ZoneMTA zone exists, omit `deliveryZone` and configure `targetHost` and optional `targetPort` instead.

### Important Warnings

**⚠️ Context Requirement**: If using `localDelivery`, you **MUST** enable the `"main"` context. The `"sender"` context is also required when using the `targetHost` fallback:
```toml
["modules/@zone-eu/zonemta-wildduck"]
enabled=["receiver", "sender", "main"]
```
The routing hook runs in `"main"`. Without a dedicated delivery zone, the `"sender"` hook keeps local and external SMTP connections isolated.

**⚠️ Duplicate Mailboxes**: If a mailbox exists in **both** Google Workspace AND WildDuck, this setting will cause unexpected behavior. Mail from ZoneMTA will always be delivered to WildDuck, even if the user expects it in Gmail. Only enable this if you're certain addresses are exclusive to one system or the other.

**⚠️ SPF on Internal Delivery**: When delivering locally via `targetHost`, the receiving server sees ZoneMTA's internal IP instead of the original sender IP. This can cause SPF checks to fail on the internal hop (e.g., `spf=fail` in Haraka logs). **DKIM signatures remain valid** and are unaffected. If SPF failures are problematic, configure your receiving server to skip SPF for trusted internal IPs (e.g., Haraka's private IP range).

**⚠️ Address Exclusivity**: This feature assumes addresses in the configured domains exist in WildDuck OR the external system, not both. Review your address allocation before enabling.

See `config.example.toml` for all available options.

## License

European Union Public License 1.1 ([details](http://ec.europa.eu/idabc/eupl.html)) or later.

> `@zone-eu/zonemta-wildduck` module is part of the Zone Mail Suite (ZMS). Suite of programs and modules for an efficient, fast and modern email server.

Copyright (c) 2024 Zone Media OÜ
