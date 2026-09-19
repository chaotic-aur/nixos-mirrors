{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.chaotic.mirror;

  nixosRevision =
    if config.system.nixos.revision == null then
      "unknown"
    else
      config.system.nixos.revision;

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

    systemd.services.chaotic-mirror-stats = {
      description = "Collects custom chaotic-aur mirror stats for node_exporter and http-root";
      path = with pkgs; [ coreutils findutils curl ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "update-mirror-stats" ''
          set -euo pipefail

          REPOS=/data/chaotic-mirror/http-root/chaotic-aur
          TEXTFILE_DIR=/var/lib/node-exporter
          PROM=$TEXTFILE_DIR/mirror.prom.tmp
          STATE_DIR=/var/lib/chaotic-mirror-stats

          fetch_upstream() {
            local repo=$1 url=$2 state="$STATE_DIR/$repo-upstream-lastupdate"
            local fetched upstream=0
            if fetched=$(curl -sf --max-time 20 "$url" 2>"$state.err"); then
              echo "$fetched" > "$state"
            else
              echo "failed to fetch upstream lastupdate for $repo from $url: $(cat "$state.err")"
            fi
            if [ -f "$state" ]; then
              upstream=$(cat "$state")
            fi
            echo "mirror_upstream_last_sync_timestamp_seconds{repo=\"$repo\"} $upstream"
          }

          {
            echo "# HELP mirror_packages_total Number of package files in the local mirror."
            echo "# TYPE mirror_packages_total gauge"
            echo "# HELP mirror_last_sync_timestamp_seconds Epoch of last successful sync (from lastupdate file)."
            echo "# TYPE mirror_last_sync_timestamp_seconds gauge"
            echo "# HELP mirror_upstream_last_sync_timestamp_seconds Epoch of upstream's last sync."
            echo "# TYPE mirror_upstream_last_sync_timestamp_seconds gauge"

            shopt -s nullglob
            for repo_dir in "$REPOS"/*/; do
              repo=$(basename "$repo_dir")
              case "$repo" in
                .*) continue ;;
              esac

              pkg_count=$(find "$repo_dir" -name '*.pkg.tar.zst' | wc -l)
              echo "mirror_packages_total{repo=\"$repo\"} $pkg_count"

              lastupdate=0
              lastupdate_file=$(find "$repo_dir" -maxdepth 2 -name lastupdate -print -quit)
              if [ -n "$lastupdate_file" ]; then
                lastupdate=$(cat "$lastupdate_file")
              fi
              echo "mirror_last_sync_timestamp_seconds{repo=\"$repo\"} $lastupdate"
            done

            fetch_upstream chaotic-aur https://builds.garudalinux.org/repos/chaotic-aur/lastupdate
            fetch_upstream garuda https://builds.garudalinux.org/repos/garuda/lastupdate

            echo "# HELP mirror_info Static mirror/host info."
            echo "# TYPE mirror_info gauge"
            echo "mirror_info{version=\"${config.system.nixos.version}\",revision=\"${nixosRevision}\",fqdn=\"${cfg.fqdn}\"} 1"
          } > "$PROM"
          mv "$PROM" "$TEXTFILE_DIR/mirror.prom"
        '';
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/chaotic-mirror-stats 0750 root root -"
    ];

    systemd.timers.chaotic-mirror-stats = {
      wantedBy = [ "timers.target" ];
      after = [ "chaotic-mirror.service" ];
      timerConfig = {
        Unit = "chaotic-mirror-stats.service";
        OnBootSec = "5m";
        OnUnitActiveSec = "5m";
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
