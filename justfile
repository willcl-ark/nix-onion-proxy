deploy:
    nix run github:nix-community/nixos-anywhere -- --flake .#hetzner-cloud nix-onion-proxy

rebuild:
    nixos-rebuild switch --flake .#hetzner-cloud --target-host nix-onion-proxy
