# TODO: backup metadata files to /storage/other
{
  # Ensure this is unique among all clans you want to use.
  meta.name = "city-watch";
  meta.tld = "watch";

  inventory.machines = {
    # Define machines here.
    vimes = {
      tags = ["commander"];
      deploy.targetHost = "root@192.168.1.180";
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

      roles.default.machines."vimes" = {};
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

      environment = {
        systemPackages = [pkgs.awscli2];
      };

      users.groups.garage = {};
      users.users.garage = {
        isNormalUser = false;
        isSystemUser = true;
        group = "garage";
      };
      users.groups.nextcloud = {};
      users.users.nextcloud = {
        isNormalUser = false;
        isSystemUser = true;
        group = "nextcloud";
      };
      services.garage = {
        enable = true;
        package = pkgs.garage;
        settings = {
          metadata_dir = "/var/lib/garage/meta";
          data_dir = "/storage/garage/data";
          db_engine = "sqlite";

          replication_factor = 1;

          rpc_bind_addr = "127.0.0.1:3901";
          rpc_public_addr = "127.0.0.1:3901";

          s3_api = {
            api_bind_addr = "127.0.0.1:3900";
            s3_region = "garage";
            root_domain = ".s3.garage";
          };

          s3_web = {
            bind_addr = "127.0.0.1:3902";
            root_domain = ".web.garage";
          };

          admin = {
            api_bind_addr = "127.0.0.1:3903";
          };
        };
      };
      # https://www.man7.org/linux/man-pages/man5/tmpfiles.d.5.html
      # https://askubuntu.com/questions/581290/what-is-the-first-number-for-in-a-4-number-chmod-argument-such-as-chmod-4555
      # https://unix.stackexchange.com/questions/577075/can-i-find-under-which-user-is-a-service-running-via-systemctl-command
      systemd.tmpfiles.rules = [
        "d /storage/garage/data 0774 garage garage"
        "d /storage/other/garage 0774 garage garage"

        "d /var/lib/nextcloud 0774 nextcloud nextcloud"
        "d /storage/other/nextcloud 0774 nextcloud nextcloud"
      ];

      services.avahi.enable = true;

      services.nextcloud = {
        # https://nixos.org/manual/nixos/stable/index.html#module-services-nextcloud
        enable = true;
        package = pkgs.nextcloud31;
        hostName = "localhost";

        # To prevent confusion caused by sops-nix
        phpOptions."realpath_cache_size" = "0";
        database.createLocally = true;
        maxUploadSize = "10G";

        settings = {
          trusted_domains = [
            "192.168.1.180"
          ];
        };
        config = {
          dbtype = "pgsql";
          adminpassFile = "${config.clan.core.vars.generators.nextcloud-shared.files.nextcloud_pwd.path}";
          objectstore.s3 = {
            bucket = "nextcloud-bucket";
            autocreate = false;
            key = "${config.clan.core.vars.generators.nextcloud-garage-shared.files.garage_key_id.value}";
            secretFile = "${config.clan.core.vars.generators.nextcloud-garage-shared.files.garage_secret_key.path}";
            hostname = "127.0.0.1";
            port = 3900;
            useSsl = false;
            region = "garage";
            usePathStyle = true;
          };
        };
      };

      clan.core.vars.generators.nextcloud-shared = {
        share = true;
        files.nextcloud_pwd = {};
        runtimeInputs = [
          pkgs.coreutils
          pkgs.openssl
        ];
        script = ''
          openssl rand -hex -out "$out"/nextcloud_pwd 32
        '';
      };

      clan.core.vars.generators.nextcloud-garage-shared = {
        share = true;
        prompts.garage_key_id = {
          description = "Garage key ID for nextcloud-bucket";
        };
        prompts.garage_secret_key = {
          description = "Garage secret key for nextcloud-bucket";
          type = "hidden";
        };
        files.garage_key_id = {};
        files.garage_secret_key = {};
        runtimeInputs = [
          pkgs.coreutils
          pkgs.openssl
        ];
        script = ''
          echo $prompts/garage_key_id > $out/garage_key_id
          echo $prompts/garage_secret_key > $out/garage_secret_key
        '';
      };

      programs.bash = {
        shellAliases = {
          garage = "GARAGE_ALLOW_WORLD_READABLE_SECRETS=true GARAGE_RPC_SECRET_FILE=/run/secrets/vars/garage-shared/rpc_secret GARAGE_ADMIN_TOKEN_FILE=/run/secrets/vars/garage/admin_token GARAGE_METRICS_TOKEN_FILE=/run/secrets/vars/garage/metrics_token garage";
          ctl = "systemctl";
          ctls = "systemctl status";
        };
      };

      boot.supportedFilesystems = ["zfs"];
      boot.zfs = {
        forceImportRoot = false;
        extraPools = ["storage"];
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    };
  };
}
