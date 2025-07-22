{
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.enable = true;

  disko.devices = {
    disk = {
      ssd = {
        name = "root-ssd";
        type = "disk";
        device = "/dev/disk/by-id/ata-Crucial_CT120M500SSD1_14170C189EF5";
        content = {
          type = "gpt";
          partitions = {
            "boot" = {
              size = "1M";
              type = "EF02"; # for grub MBR
              priority = 1;
            };
            ESP = {
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            root = {
              end = "-4G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
            swap = {
              size = "100%";
              content = {
                type = "swap";
                discardPolicy = "both";
              };
            };
          };
        };
      };
      storage1 = {
        name = "storage-hdd-1";
        type = "disk";
        device = "/dev/disk/by-id/ata-ST2000DM001-1E6164_W1E72CF2";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "storage";
              };
            };
          };
        };
      };
      storage2 = {
        name = "storage-hdd-2";
        type = "disk";
        device = "/dev/disk/by-id/ata-ST2000DM001-1CH164_Z1E85KQJ";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "storage";
              };
            };
          };
        };
      };
    };
    zpool = {
      storage = {
        type = "zpool";
        mode = "mirror";
        mountpoint = "/storage";

        datasets = {
          dataset = {
            type = "zfs_fs";
            mountpoint = "/storage/dataset";
          };
        };
      };
    };
  };
}
