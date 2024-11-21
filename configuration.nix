{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.dnsutils
    pkgs.gitMinimal
  ];

  users = {
    mutableUsers = false; # Disable useradd & passwd

    users = {
      root = {
        hashedPassword = "*"; # Disable root password
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH988C5DbEPHfoCphoW23MWq9M6fmA4UTXREiZU0J7n0 will.hetzner@temp.com" ];
      };
      nixos = {
        hashedPassword = "$y$j9T$qXvXoVtyyX0mWlq5n7ftw/$R7HLZKI6koJIMHTtvGDJOqoAhGO40/OtDLkWZhPEJPC";
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH988C5DbEPHfoCphoW23MWq9M6fmA4UTXREiZU0J7n0 will.hetzner@temp.com" ];
        isNormalUser = true;
        extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      };
      caddyProxy = {
        home = "/var/lib/caddyProxy";
        createHome = true;
        isSystemUser = true;
        group = "caddyProxy";
      };
      caddyTor = {
        home = "/var/lib/caddyTor";
        createHome = true;
        isSystemUser = true;
        group = "caddyTor";
      };
    };

    groups = {
      caddyProxy = {
        members = [ "caddyProxy" ];
      };
      caddyTor = {
        members = [ "caddyTor" ];
      };
    };
  };

  ## DNS-over-TLS
  services.stubby = {
    enable = true;
    settings = {
      # ::1 cause error, use 0::1 instead
      listen_addresses = [ "127.0.0.1" "0::1" ];
      # https://github.com/getdnsapi/stubby/blob/develop/stubby.yml.example
      resolution_type = "GETDNS_RESOLUTION_STUB";
      dns_transport_list = [ "GETDNS_TRANSPORT_TLS" ];
      tls_authentication = "GETDNS_AUTHENTICATION_REQUIRED";
      tls_query_padding_blocksize = 128;
      idle_timeout = 10000;
      round_robin_upstreams = 1;
      tls_min_version = "GETDNS_TLS1_3";
      dnssec = "GETDNS_EXTENSION_TRUE";
      upstream_recursive_servers = [
        {
          address_data = "1.1.1.2";
          tls_auth_name = "cloudflare-dns.com";
        }
        {
          address_data = "1.0.0.2";
          tls_auth_name = "cloudflare-dns.com";
        }
        {
          address_data = "2606:4700:4700::1112";
          tls_auth_name = "cloudflare-dns.com";
        }
        {
          address_data = "2606:4700:4700::1002";
          tls_auth_name = "cloudflare-dns.com";
        }
        {
          address_data = "9.9.9.9";
          tls_auth_name = "dns.quad9.net";
        }
        {
          address_data = "149.112.112.112";
          tls_auth_name = "dns.quad9.net";
        }
        {
          address_data = "2620:fe::fe";
          tls_auth_name = "dns.quad9.net";
        }
        {
          address_data = "2620:fe::9";
          tls_auth_name = "dns.quad9.net";
        }
      ];
    };
  };

  networking.nameservers = [ "::1" "127.0.0.1" ];
  services.resolved = {
    enable = true;
    fallbackDns = [ "2606:4700:4700::1112" "2606:4700:4700::1002" "1.1.1.2" "1.0.0.2" ];
  };

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    # Daily 00:00
    dates = "daily UTC";
  };

  system.stateVersion = "24.05";
}
