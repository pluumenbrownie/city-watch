{pkgs, ...}: let
  garage = {
    pkgs,
    wrappers,
    ...
  }:
    wrappers.lib.wrapPackage
    ({
      config,
      wlib,
      lib,
      ...
    }: {
      inherit pkgs;
      package = pkgs.garage;
      env = {
        GARAGE_ALLOW_WORLD_READABLE_SECRETS = "true";
        GARAGE_RPC_SECRET_FILE = "${config.clan.core.vars.generators.garage-shared.files.rpc_secret.path}";
        GARAGE_ADMIN_TOKEN_FILE = "${config.clan.core.vars.generators.garage.files.admin_token.path}";
        GARAGE_METRICS_TOKEN_FILE = "${config.clan.core.vars.generators.garage.files.metrics_token.path}";
      };
    }).config.wrap {inherit pkgs;};
in {
  config = {
    environment.systemPackages = [garage];
    services.garage = {
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
