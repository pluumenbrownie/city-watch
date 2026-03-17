inputs: {
  imports = [
    ./garage.nix
  ];
  options = {
    wrappedPackages = inputs.lib.mkOption {};
  };
}
