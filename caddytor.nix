{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.caddyTor;
in {
  options.services.caddyTor = {
    enable = mkEnableOption "Caddy web server";

    config = mkOption {
      type = types.path;
      default = "/etc/caddy/caddyTor.conf";
      description = "Path to the Caddy configuration file.";
    };

    configFile = mkOption {
      type = types.path;
      description = "Path to Caddyfile on the build machine";
    };

    configText = mkOption {
      type = types.lines;
      default = "";
      description = "Direct content of the Caddyfile";
    };

    adapter = mkOption {
      default = "caddyfile";
      example = "nginx";
      type = types.str;
      description = ''
        Name of the config adapter to use.
        See https://caddyserver.com/docs/config-adapters for the full list.
      '';
    };

    dataDir = mkOption {
      default = "/var/lib/caddyTor";
      type = types.path;
      description = ''
        The data directory, for storing certificates. Before 17.09, this
        would create a .caddy directory. With 17.09 the contents of the
        .caddy directory are in the specified data directory instead.
      '';
    };

    package = mkOption {
      default = pkgs.caddy;
      defaultText = "pkgs.caddy";
      type = types.package;
      description = "Caddy package to use.";
    };
  };

  config = mkIf cfg.enable {
    environment.etc."caddy/caddyTor.conf".source =
      if cfg.configText != ""
      then (pkgs.writeText "caddyTor.conf" cfg.configText)
      else cfg.configFile;
    systemd.services.caddyTor = {
      description = "Caddy web server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ]; # systemd-networkd-wait-online.service
      wantedBy = [ "multi-user.target" ];
      startLimitIntervalSec = 14400;
      startLimitBurst = 10;
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/caddy run --config ${cfg.config} --adapter ${cfg.adapter}";
        ExecReload = "${cfg.package}/bin/caddy reload --config ${cfg.config} --adapter ${cfg.adapter}";
        Type = "simple";
        User = "caddyTor";
        Group = "caddyTor";
        Restart = "on-abnormal";
        # < 20.09
        # https://github.com/NixOS/nixpkgs/pull/97512
        # StartLimitIntervalSec = 14400;
        # StartLimitBurst = 10;
        NoNewPrivileges = true;
        LimitNPROC = 512;
        LimitNOFILE = 1048576;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectHome = true;
        ProtectSystem = "full";
        ReadWriteDirectories = cfg.dataDir;
        KillMode = "mixed";
        KillSignal = "SIGQUIT";
        TimeoutStopSec = "5s";
      };
    };

    users.users.caddyTor = {
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.caddyTor = {
      members = [ "caddyTor" ];
    };
  };
}
