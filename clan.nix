{
  # Ensure this is unique among all clans you want to use.
  meta.name = "city-watch";

  inventory.machines = {
    # Define machines here.
    vimes = {
      tags = [];
      deploy.targetHost = "root@192.168.1.183";
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
  };

  # Additional NixOS configuration can be added here.
  # machines/jon/configuration.nix will be automatically imported.
  # See: https://docs.clan.lol/guides/more-machines/#automatic-registration
  machines = {
    # jon = { config, ... }: {
    #   environment.systemPackages = [ pkgs.asciinema ];
    # };
    vimes = {
      config,
      pkgs,
      ...
    }: {
      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+WzQti2XAEbUcQ48olNRJcleDeJ714fZX2bJulJPGu wessel@ultrapc"
      ];
    };
  };
}
