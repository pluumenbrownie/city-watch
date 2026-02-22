# TODO: backup metadata files to /storage/other
{
  # Ensure this is unique among all clans you want to use.
  meta.name = "city-watch";
  meta.domain = "watch";

  inventory.machines = {
    vimes = {
      tags = ["commander"];
      deploy.targetHost = "root@192.168.1.183";
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

    garage = {
      roles.default.machines."server" = {};
    };
  };

  machines = {
    vimes = {pkgs, ...}: {
      imports = [
        ./services/postgres.nix
        ./services/hedgedoc.nix
        # ./services/garage.nix
        ./modules
      ];
    };
  };
}
