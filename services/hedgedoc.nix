{config, ...}: {
  config = {
    storageDirs = {
      hedgedocUploads = {
        user = "hedgedoc";
        path = "uploads";
      };
    };
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        3000
      ];
      allowedUDPPorts = [
        3000
      ];
    };

    databases = [
      "hedgedoc"
    ];

    services = {
      hedgedoc = {
        enable = true;
        settings = {
          db = {
            username = "hedgedoc";
            database = "hedgedoc";
            host = "/run/postgresql";
            dialect = "postgresql";
          };
          domain = "192.168.1.183:3000";
          host = "192.168.1.183";
          # protocolUseSSL = true;
          uploadsPath = config.storageDirs.hedgedocUploads.fullPath;
        };
      };
    };
  };
}
