{...}: {
  config = {
    # https://www.man7.org/linux/man-pages/man5/tmpfiles.d.5.html
    # https://askubuntu.com/questions/581290/what-is-the-first-number-for-in-a-4-number-chmod-argument-such-as-chmod-4555
    # https://unix.stackexchange.com/questions/577075/can-i-find-under-which-user-is-a-service-running-via-systemctl-command
    systemd.tmpfiles.rules = [
      "d /storage/hedgedoc/uploads 0700 hedgedoc hedgedoc"
    ];

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
          uploadsPath = "/storage/hedgedoc/uploads";
        };
      };
    };
  };
}
