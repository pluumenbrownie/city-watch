{
  inputs,
  pkgs,
  config,
  ...
}: {
  wrappedPackages.garage = inputs.wrappers.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.garage_2;
    env = {
      GARAGE_ALLOW_WORLD_READABLE_SECRETS = "true";
      GARAGE_RPC_SECRET_FILE = "${config.clan.core.vars.generators.garage-shared.files.rpc_secret.path}";
      GARAGE_ADMIN_TOKEN_FILE = "${config.clan.core.vars.generators.garage.files.admin_token.path}";
      GARAGE_METRICS_TOKEN_FILE = "${config.clan.core.vars.generators.garage.files.metrics_token.path}";
    };
  };
}
