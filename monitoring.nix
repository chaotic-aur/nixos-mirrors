{ lib, ... }:
{
  services.fluent-bit = {
    enable = true;
    settings = {
      service = {
        Flush = 1;
        Daemon = false;
        Log_Level = "info";
      };

      pipeline = {
        inputs = [
          {
            name = "systemd";
            tag = "host.*";
            read_from_tail = true;
            strip_underscores = true;
            lowercase = true;
            systemd_filter = [
              "_SYSTEMD_UNIT=docker.service"
              "_SYSTEMD_UNIT=chaotic-mirror.service"
              "_SYSTEMD_UNIT=chaotic-mirror-vnstat.service"
              "_SYSTEMD_UNIT=sshd.service"
              "_SYSTEMD_UNIT=ssh.service"
            ];
            systemd_filter_type = "or";
          }
          {
            name = "forward";
            tag = "docker.*";
            listen = "127.0.0.1";
            port = 24224;
          }
        ];

        filters = [
          {
            name = "grep";
            match = "*";
            logical_op = "or";
            exclude = "$message level=(info|debug)";
          }
        ];

        outputs = [
          {
            name = "loki";
            match = "*";
            host = "monitoring";
            port = 3030;
            labels = "service=$systemd_unit,host=$hostname";
            tenant_id = "garuda";
            drop_single_key = "on";
            line_format = "json";
          }
        ];
      };
    };
  };

  virtualisation.docker.daemon.settings = {
    log-driver = "fluentd";
    log-opts = {
      fluentd-address = "127.0.0.1:24224";
      tag = "docker.{{.Name}}";
    };
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # Prometheus node exporter scraped over the tailnet
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  systemd.tmpfiles.rules = [
    "d /var/lib/node-exporter 0755 root root -"
  ];
  services.prometheus.exporters.node = {
    enable = true;
    port = 3021;
    enabledCollectors = [ "systemd" "textfile" ];
    extraFlags = [ "--collector.textfile.directory=/var/lib/node-exporter" ];
    openFirewall = false;
  };
}
