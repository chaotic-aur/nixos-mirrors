{ config, lib, pkgs, inputs, ... }:
with lib;
let
  cfg = config.chaotic.mirror;
  fqdnParts = splitString "." cfg.fqdn;
  generatedAcmeHost = if (length fqdnParts) > 2 then concatStringsSep "." (tail fqdnParts) else cfg.fqdn;
  acmeHost = if cfg.acmeHost == "" then generatedAcmeHost else cfg.acmeHost;
  statsFile = "${cfg.root}/stats";
  statsImage = "${cfg.root}/stats.png";
in
{
  config = mkIf (cfg.enable && cfg.native) (mkMerge [
    {
      services.nginx = {
        enable = true;
        virtualHosts.${cfg.fqdn} = {
          forceSSL = true;
          http3 = true;
          http3_hq = true;
          kTLS = true;
          quic = true;
          root = cfg.root;
          useACMEHost = acmeHost;
          locations = {
            "~* ^/chaotic-aur/([^/]+)/x86_64/(?!1.(db|files))[^/]+$" = {
              extraConfig = ''
                add_header Cache-Control "max-age=150, stale-while-revalidate=150, stale-if-error=86400";
              '';
            };
            "/" = {
              extraConfig = ''
                autoindex on;
                autoindex_exact_size off;
                autoindex_localtime on;
                add_header Cache-Control 'no-cache';
              '';
            };
          };
        };
      };

      services.syncthing = {
        enable = true;
        guiAddress = "127.0.0.1:8384";
        package = inputs.syncthing-nixpkgs.legacyPackages.${pkgs.system}.syncthing;
        openDefaultPorts = true;
        overrideDevices = false;
        overrideFolders = false;
        settings = {
          options.urAccepted = -1;
          folders.${cfg.syncthingFolderName} = {
            id = cfg.syncthingFolderId;
            path = "${cfg.root}/${cfg.syncthingFolderName}";
            type = "receiveonly";
            order = "oldestFirst";
          };
        };
      };

      systemd.services.vnstat-image = {
        description = "Generate vnstat statistics image";
        path = with pkgs; [ coreutils vnstat ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          mkdir -p ${escapeShellArg cfg.root}
          vnstat -i ${escapeShellArg cfg.vnstatInterface} > ${escapeShellArg statsFile}
          vnstati -L -vs -o ${escapeShellArg statsImage} --scale 500
        '';
      };

      systemd.timers.vnstat-image = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.vnstatImageSchedule;
          Persistent = true;
        };
      };
    }
    (mkIf config.services.nginx.enable {
      security.acme = {
        acceptTerms = true;
        defaults = {
          group = "nginx";
          email = cfg.email;
        };
        certs.${acmeHost} = {
          webroot = "/var/lib/acme/acme-challenges";
        };
      };
    })
  ]);
}
