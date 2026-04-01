{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.chaotic.mirror;

  mirrorconfig = pkgs.writeText "mirrorconfig" ''
    DOMAIN_NAME=${cfg.fqdn}
    EMAIL=${cfg.email}
  '';
in
{
  options.chaotic.mirror = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the chaotic-aur mirror.";
    };
    fqdn = mkOption {
      type = types.str;
      description = "The fully qualified domain name of the mirror.";
    };
    email = mkOption {
      type = types.str;
      description = "The email address of the mirror administrator. Used for letsencrypt certificate registration.";
    };
    stats = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to save vnstat statistics to a file in the http-root.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.docker.enable = true;

    systemd.services.chaotic-mirror = {
      description = "Chaotic-AUR mirror";
      after = [ "network-online.target" "docker.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ git bashNonInteractive docker host ];
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = pkgs.writeShellScript "dns-wait" ''
          set -euo pipefail

          for i in {1..6}; do
              if host github.com; then
                  exit 0
              fi
              echo "Waiting for network..."
              sleep 5
          done

          echo "Timed out waiting for network"
          exit 1
        '';
        ExecStart = pkgs.writeShellScript "run-mirror" ''
          set -euo pipefail

          if [ ! -d /data/chaotic-mirror/.git ]; then
              git clone https://github.com/chaotic-aur/docker-mirror /data/chaotic-mirror
          fi

          cd /data/chaotic-mirror

          cp "${mirrorconfig}" .env

          ./mirrorctl update
        '';
      };
    };

    systemd.services.chaotic-mirror-vnstat = mkIf cfg.stats {
      description = "Updates the chaotic-aur mirror vnstat statistics in the http-root";
      path = with pkgs; [ vnstat ];
      serviceConfig = {
        Type = "oneshot";
        RemmainAfterExit = true;
        ExecStart = pkgs.writeShellScript "update-vnstat" ''
          set -euo pipefail
          if [ ! -d "/data/chaotic-mirror/http-root" ]; then
            echo "http-root does not exist, skipping vnstat stats update"
            exit 0
          fi

          vnstat > "/data/chaotic-mirror/http-root/stats.txt"
          vnstati --scale 500 -L -vs -o "/data/chaotic-mirror/http-root/stats.png"
        '';
      };
    };

    systemd.timers.chaotic-mirror-vnstat = mkIf cfg.stats {
      wantedBy = [ "timers.target" ];
      after = [ "chaotic-mirror.service" ];
      timerConfig = {
        Unit = "chaotic-mirror-vnstat.service";
        OnBootSec = "5m";
        OnUnitActiveSec = "5m";
      };
    };
  };
}
