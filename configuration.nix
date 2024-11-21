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
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH988C5DbEPHfoCphoW23MWq9M6fmA4UTXREiZU0J7n0 will.hetzner@temp.com" ]
      };
      nixos = {
        hashedPassword = "$y$j9T$qXvXoVtyyX0mWlq5n7ftw/$R7HLZKI6koJIMHTtvGDJOqoAhGO40/OtDLkWZhPEJPC";
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH988C5DbEPHfoCphoW23MWq9M6fmA4UTXREiZU0J7n0 will.hetzner@temp.com" ]
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

  system.stateVersion = "24.05";
}
