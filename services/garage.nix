{
  config,
  pkgs,
  ...
}: {
  config = {
    users.users = {
      garage = {
        isSystemUser = true;
        extraGroups = ["wheel"];
        group = "garage";
      };
    };
    users.groups = {
      garage = {};
    };

    systemd.tmpfiles.rules = [
      "d /storage/garage/data 0700 garage garage"
    ];

    environment.systemPackages = [config.wrappedPackages.garage];
    services.garage = {
      enable = true;
      package = pkgs.garage_2;
      settings = {
        data_dir = [
          {
            capacity = "2T";
            path = "/storage/garage/data";
          }
        ];
        db_engine = "sqlite";

        replication_factor = 1;

        rpc_bind_addr = "127.0.0.1:3901";

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
  };
}
