{
  inputs.clan-core.url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
  inputs.nixpkgs.follows = "clan-core/nixpkgs";
  inputs.wrappers.url = "github:Lassulus/wrappers";
  inputs.wrappers.inputs.wrappers.follows = "clan-core/nixpkgs";

  outputs = {
    self,
    clan-core,
    nixpkgs,
    ...
  } @ inputs: let
    # Usage see: https://docs.clan.lol
    clan = clan-core.lib.clan {
      inherit self;
      imports = [./clan.nix];
      specialArgs = {inherit inputs;};
    };

    pkgs = nixpkgs.legacyPackages."x86_64-linux";

    python = pkgs.python3.override {
      self = python;
      packageOverrides = pyfinal: pyprev: {
        garage_admin_sdk = pyfinal.callPackage ./pkgs/python/garage_sdk.nix {};
      };
    };
  in {
    inherit (clan.config) nixosConfigurations nixosModules clanInternals;
    clan = clan.config;
    # Add the Clan cli tool to the dev shell.
    # Use "nix develop" to enter the dev shell.
    devShells =
      nixpkgs.lib.genAttrs
      [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ]
      (system: {
        default = clan-core.inputs.nixpkgs.legacyPackages.${system}.mkShell {
          packages = [
            clan-core.packages.${system}.clan-cli
            pkgs.disko
            (python.withPackages (pypkgs:
              with pypkgs; [
                minio
                garage_admin_sdk
              ]))
          ];
        };
      });
  };
}
