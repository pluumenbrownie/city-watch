# TODO: backup metadata files to /storage/other
{
  # Ensure this is unique among all clans you want to use.
  meta.name = "city-watch";
  meta.domain = "watch";

  inventory.machines = {
    vimes = {
      tags = ["commander"];
      deploy.targetHost = "root@192.168.1.182";
    };
  };

  inventory.instances = {
    admin = {
      roles.default.tags.all = {};
      roles.default.settings.allowedKeys = {
        ultrapc = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILMv4jxCrKDjbeFhO57v+V6Ck12zVkGfOTGJhr2GNs4y wessel@ultrapc";
      };
    };

    zerotier = {
      roles.controller.machines."vimes" = {};
      roles.peer.tags.all = {};
    };
  };

  machines = {
    vimes = {pkgs, ...}: {
      environment.etc."issue.d/ip.issue".text = "\\4\n";
      networking.dhcpcd.runHook = "${pkgs.utillinux}/bin/agetty --reload";

      users.users = {
        postgres = {
          isSystemUser = true;
          extraGroups = ["wheel"];
        };
      };

      # https://www.man7.org/linux/man-pages/man5/tmpfiles.d.5.html
      # https://askubuntu.com/questions/581290/what-is-the-first-number-for-in-a-4-number-chmod-argument-such-as-chmod-4555
      # https://unix.stackexchange.com/questions/577075/can-i-find-under-which-user-is-a-service-running-via-systemctl-command
      systemd.tmpfiles.rules = [
        "d /storage/postgresql/15 0774 postgres postgres"
      ];

      services = {
        hedgedoc = {
          enable = true;
        };
        postgresql = {
          enable = true;
          dataDir = "/storage/postgresql/15";
        };
      };
    };
  };
}
