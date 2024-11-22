# NixOS onion proxy using caddy

Proxy from onion to clearnet domain.

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

## Configure onion host

To use a specific onion hostname, ssh into the server and update the onion keypair:

```bash
ssh <host>
cd /var/lib/tor/onion/bitcoinCoreOrg
# modify hs_ed25519_secret_key
# modify hs_ed25519_public_key
rm hostname
sudo systemctl restart tor.service
```

## Rebuild

Make changes, stage in git and then:

```bash
just rebuild
```

or:

```bash
nix run nixpkgs#nixos-rebuild -- switch --flake .#hetzner-cloud --target-host <host>
```

##### Notes

*caddyTor.nix* inspired by: https://mdleom.com/blog/2020/03/14/caddy-nixos-part-3/ ([archive.today](http://archive.today/cU0RK))
