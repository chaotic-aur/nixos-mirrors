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
  };

  config = mkIf cfg.enable {
    virtualisation.docker.enable = true;

    systemd.services.chaotic-mirror = {
      description = "Chaotic-AUR mirror";
      after = [ "network-online.target" "docker.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ git bashNonInteractive docker ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "run-mirror" ''
          set -euo pipefail

          if [ ! -d /opt/chaotic-mirror ]; then
              git clone https://github.com/chaotic-aur/docker-mirror /opt/chaotic-mirror
          fi

          cd /opt/chaotic-mirror

          cp "${mirrorconfig}" .env

          ./mirrorctl update
        '';
      };
    };
  };
}
