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
    ./caddytor.nix
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
      caddyTor = {
        home = "/var/lib/caddyTor";
        createHome = true;
        isSystemUser = true;
        group = "caddyTor";
      };
    };

    groups = {
      caddyTor = {
        members = [ "caddyTor" ];
      };
    };
  };

  ## DNS-over-TLS
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = ["127.0.0.1" "::1"];
        access-control = [
          "127.0.0.0/8 allow"
          "::1/128 allow"
        ];
        # Use TCP for upstream queries (better for TLS)
        tcp-upstream = true;
        # Enable DNSSEC validation
        auto-trust-anchor-file = "/var/lib/unbound/root.key";
      };
      forward-zone = [
        {
          name = ".";
          forward-tls-upstream = "yes";
          forward-addr = [
            "1.1.1.2@853#security.cloudflare-dns.com"
            "1.0.0.2@853#security.cloudflare-dns.com"
            "2606:4700:4700::1112@853#security.cloudflare-dns.com"
            "2606:4700:4700::1002@853#security.cloudflare-dns.com"
          ];
        }
      ];
    };
  };

  networking.nameservers = [ "::1" "127.0.0.1" ];
  services.resolved = {
    enable = true;
    fallbackDns = [ "2606:4700:4700::1112" "2606:4700:4700::1002" "1.1.1.2" "1.0.0.2" ];
  };

  ## Enable BBR module
  boot.kernelModules = [ "tcp_bbr" ];

  ## Network hardening and performance
  boot.kernel.sysctl = {
    # Disable magic SysRq key
    "kernel.sysrq" = 0;
    # Ignore ICMP broadcasts to avoid participating in Smurf attacks
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    # Ignore bad ICMP errors
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    # Reverse-path filter for spoof protection
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    # SYN flood protection
    "net.ipv4.tcp_syncookies" = 1;
    # Do not accept ICMP redirects (prevent MITM attacks)
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    # Do not send ICMP redirects (we are not a router)
    "net.ipv4.conf.all.send_redirects" = 0;
    # Do not accept IP source route packets (we are not a router)
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    # Protect against tcp time-wait assassination hazards
    "net.ipv4.tcp_rfc1337" = 1;
    # TCP Fast Open (TFO)
    "net.ipv4.tcp_fastopen" = 3;
    ## Bufferbloat mitigations
    # Requires >= 4.9 & kernel module
    "net.ipv4.tcp_congestion_control" = "bbr";
    # Requires >= 4.19
    "net.core.default_qdisc" = "cake";
  };

  ## Tor onion
  services.tor = {
    client.enable = true;
    enable = true;
    enableGeoIP = false;
    relay.onionServices = {
      bitcoinCoreOrg = {
        version = 3;
        map = [{
          port = 80;
          target = {
            addr = "[::1]";
            port = 8080;
          };
        }];
      };
    };
    settings = {
      ClientUseIPv4 = true;
      ClientUseIPv6 = true;
      ClientPreferIPv6ORPort = true;
    };
  };

  services.caddyTor = {
    enable = true;
    configFile = ./caddyfile;
  };

  services.snowflake-proxy = {
    enable = true;
    capacity = 100;
  };

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    # Daily 00:00
    dates = "daily UTC";
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    extraOptions = ''
      min-free = ${toString (500 * 1024 * 1024)}
    '';

    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  system.stateVersion = "24.05";
}
