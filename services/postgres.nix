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
    storageDirs = {
      postgres15 = {
        user = "postgres";
        path = "postgresql/15";
        wheelAccess = true;
      };
    };

    services.postgresql = {
      enable = true;
      dataDir = config.storageDirs.postgres15.fullPath;
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
