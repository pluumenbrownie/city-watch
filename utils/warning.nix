{
  config,
  pkgs,
  lib,
  ...
}: {
  # 1. Write failed units to a status file on demand
  systemd.services.check-failed-units = {
    description = "Check for failed systemd units";
    script = ''
      failed=$(${pkgs.systemd}/bin/systemctl list-units --state=failed --no-legend --no-pager)
      if [ -n "$failed" ]; then
        echo "$failed" > /var/lib/failed-units/status
      else
        rm -f /var/lib/failed-units/status
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "failed-units";
    };
  };

  # 2. Also keep the timer as a fallback
  systemd.timers.check-failed-units = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "5min";
    };
  };

  # 3. Trigger the check on every SSH login via PAM
  security.pam.services.sshd.text = lib.mkDefault ''
    # Run the failed-units check synchronously on SSH login
    session optional ${pkgs.systemd}/lib/security/pam_systemd.so
    session required pam_exec.so ${pkgs.writeShellScript "pam-check-failed-units" ''
      if [ "$PAM_TYPE" = "open_session" ]; then
        ${pkgs.systemd}/bin/systemctl start --wait check-failed-units.service
      fi
    ''}
    session required pam_env.so
    session required pam_unix.so
    auth required pam_unix.so
    account required pam_unix.so
  '';

  # 4. Dynamic MOTD script that reads the status file
  environment.etc."profile.d/failed-units-motd.sh" = {
    text = ''
      if [ -f /var/lib/failed-units/status ]; then
        echo -e "\033[1;31m"
        echo "╔══════════════════════════════════════════╗"
        echo "║      ⚠  FAILED SYSTEMD UNITS DETECTED    ║"
        echo "╠══════════════════════════════════════════╣"
        while IFS= read -r line; do
          printf "║  %-40s║\n" "$line"
        done < /var/lib/failed-units/status
        echo "╚══════════════════════════════════════════╝"
        echo -e "\033[0m"
      fi
    '';
    mode = "0644";
  };

  # 5. Source the MOTD script on interactive shell init
  programs.bash.interactiveShellInit = ''
    if [ -f /etc/profile.d/failed-units-motd.sh ]; then
      source /etc/profile.d/failed-units-motd.sh
    fi
  '';

  services.openssh = {
    enable = true;
    settings.PrintMotd = true;
  };
}
