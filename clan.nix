{
  # Ensure this is unique among all clans you want to use.
  meta.name = "city-watch";
  meta.tld = "watch";

  inventory.machines = {
    # Define machines here.
    vimes = {
      tags = ["commander"];
    };
  };

  # Docs: See https://docs.clan.lol/reference/clanServices
  inventory.instances = {
    # Docs: https://docs.clan.lol/reference/clanServices/admin/
    # Admin service for managing machines
    # This service adds a root password and SSH access.
    admin = {
      roles.default.tags.all = {};
      roles.default.settings.allowedKeys = {
        # Insert the public key that you want to use for SSH access.
        # All keys will have ssh access to all machines ("tags.all" means 'all machines').
        # Alternatively set 'users.users.root.openssh.authorizedKeys.keys' in each machine
        ultrapc = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILMv4jxCrKDjbeFhO57v+V6Ck12zVkGfOTGJhr2GNs4y wessel@ultrapc";
      };
    };

    # Docs: https://docs.clan.lol/reference/clanServices/zerotier/
    # The lines below will define a zerotier network and add all machines as 'peer' to it.
    # !!! Manual steps required:
    #   - Define a controller machine for the zerotier network.
    #   - Deploy the controller machine first to initilize the network.
    zerotier = {
      # Replace with the name (string) of your machine that you will use as zerotier-controller
      # See: https://docs.zerotier.com/controller/
      # Deploy this machine first to create the network secrets
      roles.controller.machines."vimes" = {};
      # Peers of the network
      # tags.all means 'all machines' will joined
      roles.peer.tags.all = {};
    };

    garage = {
      # https://nixos.org/manual/nixos/stable/#module-services-garage

      roles.default.machines."vimes".settings = {};
    };
  };

  # Additional NixOS configuration can be added here.
  # machines/jon/configuration.nix will be automatically imported.
  # See: https://docs.clan.lol/guides/more-machines/#automatic-registration
  machines = {
    vimes = {
      config,
      pkgs,
      ...
    }: {
      environment.etc."issue.d/ip.issue".text = "\\4\n";
      networking.dhcpcd.runHook = "${pkgs.utillinux}/bin/agetty --reload";

      services.garage = {
        enable = true;
        package = pkgs.garage_2;

        settings = {
          metadata_dir = "/var/lib/garage/meta";
          data_dir = "/var/lib/garage/data";

          replication_factor = 1;

          rpc_bind_addr = "[::]:3901";
          rpc_public_addr = "127.0.0.1:3901";

          s3_api = {
            api_bind_addr = "127.0.0.1:3900";
            s3_region = "garage";
            root_domain = ".s3.garage";
          };

          s3_web = {
            bind_addr = "[::]:3902";
            root_domain = ".web.garage";
          };

          admin = {
            api_bind_addr = "127.0.0.1:3903";
          };
        };
      };
      services.avahi.enable = true;
    };
  };
}
