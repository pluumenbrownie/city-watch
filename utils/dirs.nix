{
  config,
  lib,
  ...
}: let
  storageBaseDir = "/storage";
in {
  options.storageDirs = lib.mkOption {
    description = "Managed storage directories, created via systemd-tmpfiles, with associated system users. Made by Claude 4.6.";
    default = {};
    example = lib.literalExpression ''
      {
        programData = {
          path        = "data";
          user        = "program";
        };
        adminData = {
          path        = "admin";
          user        = "adminservice";
          permissions = "0755";
          wheelAccess = true;
        };
      }
    '';
    type = lib.types.attrsOf (lib.types.submodule ({config, ...}: {
      options = {
        path = lib.mkOption {
          type = lib.types.str;
          description = "Path relative to ${storageBaseDir}.";
        };

        user = lib.mkOption {
          type = lib.types.str;
          description = "Owner user (and group) of the directory. A system user with this name will be created.";
        };

        permissions = lib.mkOption {
          type = lib.types.str;
          default = "0700";
          description = "Directory permissions in octal notation.";
        };

        wheelAccess = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to add the user to the wheel group.";
        };

        fullPath = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          description = "Computed absolute path. Use this to reference the directory.";
        };
      };

      config = {
        fullPath = "${storageBaseDir}/${config.user}/${config.path}";
      };
    }));
  };

  config = let
    dirs = lib.attrValues config.storageDirs;
  in {
    # https://www.man7.org/linux/man-pages/man5/tmpfiles.d.5.html
    # https://askubuntu.com/questions/581290/what-is-the-first-number-for-in-a-4-number-chmod-argument-such-as-chmod-4555
    # https://unix.stackexchange.com/questions/577075/can-i-find-under-which-user-is-a-service-running-via-systemctl-command
    systemd.tmpfiles.rules =
      map (
        d: "d ${d.fullPath} ${d.permissions} ${d.user} ${d.user} - -"
      )
      dirs;

    # Key by d.user so the created user matches the tmpfiles rule
    users.users = lib.listToAttrs (map (d: {
        name = d.user;
        value = {
          isSystemUser = true;
          group = d.user;
          extraGroups = lib.optional d.wheelAccess "wheel";
        };
      })
      dirs);

    users.groups = lib.listToAttrs (map (d: {
        name = d.user;
        value = {};
      })
      dirs);
  };
}
