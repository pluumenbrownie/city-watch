{
  lib,
  config,
  ...
}: {
  options = {
    databases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Databases to add to the postgres database. Will be used for both name and user";
    };
  };
  config = {
    users.users = {
      postgres = {
        isSystemUser = true;
        extraGroups = ["wheel"];
        group = "postgres";
      };
    };
    users.groups = {
      postgres = {};
    };

    systemd.tmpfiles.rules = [
      # https://dba.stackexchange.com/questions/299080/failed-to-access-postgres-data-directory-on-vm
      "d /storage/postgresql/15 0700 postgres postgres"
    ];

    services.postgresql = {
      enable = true;
      dataDir = "/storage/postgresql/15";
      ensureUsers =
        map (name: {
          name = name;
          ensureDBOwnership = true;
        })
        config.databases;
      ensureDatabases = config.databases;
    };
  };
}
