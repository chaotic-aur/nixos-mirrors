{ lib, ... }:
{
  disko.devices = {
    disk.disk = {
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          esp = {
            name = "ESP";
            size = "500M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          data = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/data";
              postMountHook = "mkdir -p /mnt/data/nix";
            };
          };
        };
      };
    };
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "size=50%"
          "defaults"
          "mode=755"
        ];
      };
      "/nix" = {
        device = "/data/nix";
        fsType = "none";
        mountOptions = [
          "bind"
        ];
      };
    };
  };

  fileSystems."/data".neededForBoot = true;
  fileSystems."/nix".depends = [ "/data" ];
}
