{pkgs, ...}: {
  config = {
    environment.etc."issue.d/ip.issue".text = "\\4\n";
    networking.dhcpcd.runHook = "${pkgs.utillinux}/bin/agetty --reload";
    time.timeZone = "Europe/Amsterdam";

    environment.systemPackages = [
      pkgs.lnav
    ];
  };
}
