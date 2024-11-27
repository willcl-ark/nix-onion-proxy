# bitcoincore.org onion proxy using caddy

Proxy from a hidden service to bitcoincore.org clearnet site.

- Runs a hidden service which is proxied to bitcoincore.org using Caddy's `reverse_proxy` directive.
- DNS lookup is handled by `unbound` using DNS-over-TLS and DNSSEC validation.

## Usage

Either modify the *justfile*, switching "nix-onion-proxy" to your \<user\>@\<hostname\>, and run:

```bash
just deploy
```

or:

```bash
nix run github:nix-community/nixos-anywhere -- --flake .#hetzner-cloud <host>
```

> [!NOTE]
> Sometimes requires running it twice on first deployment

## Configure onion

### Find the generated onion hostname

SSH into the server and locate the hostname:

```bash
ssh <host> "cat /var/lib/tor/onion/bitcoinCoreOrg/onion/hostname"
```

### Use a custom hostname

To use a specific onion hostname, ssh into the server and update the onion key (pair) and hostname files with your own and restart the Tor service:

```bash
ssh <host>
cd /var/lib/tor/onion/bitcoinCoreOrg

# modify hs_ed25519_secret_key
# modify hs_ed25519_public_key
# modify hostname

sudo systemctl restart tor.service
```

## Rebuild following configuration changes

Make changes, stage in git and then:

```bash
just rebuild
```

or:

```bash
nix run nixpkgs#nixos-rebuild -- switch --flake .#hetzner-cloud --target-host <host>
```

Sometimes changes to Tor/Caddy do not trigger a unit file restart. If your changes are not applied, restart these manually:

```bash
ssh <host>
systemctl restart caddyTor.service tor.service
```

##### Notes

*caddyTor.nix* inspired by: https://mdleom.com/blog/2020/03/14/caddy-nixos-part-3/ ([archive.today](http://archive.today/cU0RK))

Example site at [tor://bitcoinybownr6vbjvxnhfxlfbvw3kdrhry7w56ds4v3sm37d74zl5id.onion](tor://bitcoinybownr6vbjvxnhfxlfbvw3kdrhry7w56ds4v3sm37d74zl5id.onion)
