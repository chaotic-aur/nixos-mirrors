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
  config = mkIf (cfg.enable && !cfg.native) {
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
  };
}
