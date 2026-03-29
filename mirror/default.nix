{ lib, ... }:
with lib;
{
  imports = [
    ./docker.nix
    ./native.nix
  ];

  options.chaotic.mirror = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the chaotic-aur mirror.";
    };

    native = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to use the native mirror stack (nginx/acme/syncthing) instead of Docker.";
    };

    fqdn = mkOption {
      type = types.str;
      description = "The fully qualified domain name of the mirror.";
    };

    email = mkOption {
      type = types.str;
      description = "The email address of the mirror administrator. Used for letsencrypt certificate registration.";
    };

    acmeHost = mkOption {
      type = types.str;
      default = "";
      description = "ACME host to use for nginx virtual host certificates. When empty, generated from fqdn by dropping the first DNS label.";
    };

    root = mkOption {
      type = types.str;
      default = "/srv/http";
      description = "Filesystem root path for the mirror web content.";
    };

    syncthingFolderId = mkOption {
      type = types.str;
      default = "jhcrt-m2dra";
      description = "Syncthing folder ID for the chaotic-aur mirror folder.";
    };

    syncthingFolderName = mkOption {
      type = types.str;
      default = "chaotic-aur";
      description = "Syncthing folder name for the chaotic-aur mirror folder.";
    };

    vnstatInterface = mkOption {
      type = types.str;
      default = "eno1";
      description = "Network interface used by vnstat image generation.";
    };

    vnstatImageSchedule = mkOption {
      type = types.str;
      default = "daily";
      description = "systemd OnCalendar expression for vnstat image generation.";
    };
  };
}
