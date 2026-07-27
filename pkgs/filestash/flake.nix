{
  description = "Filestash — universal file storage client";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};

        # ── Static library overrides ───────────────────────────────────────────

        libjpegStatic = pkgs.libjpeg.overrideAttrs (old: {
          cmakeFlags =
            (old.cmakeFlags or [])
            ++ [
              "-DENABLE_SHARED=OFF"
              "-DENABLE_STATIC=ON"
            ];
        });

        libpngStatic = pkgs.libpng.overrideAttrs (old: {
          configureFlags =
            (old.configureFlags or [])
            ++ [
              "--disable-shared"
              "--enable-static"
            ];
        });

        zlibStatic = pkgs.zlib.static;

        libwebpStatic = pkgs.libwebp.overrideAttrs (old: {
          cmakeFlags = (old.cmakeFlags or []) ++ ["-DBUILD_SHARED_LIBS=OFF"];
        });

        # libraw: C++ / autoconf. Build only the .la targets, skip sample
        # binaries that require libstdc++. Collapse to a single output so we
        # don't have to satisfy the upstream "out/lib/dev/doc" split.
        librawStatic = pkgs.libraw.overrideAttrs (old: {
          outputs = ["out"]; # collapse multi-output; everything goes to $out

          configureFlags = (old.configureFlags or []) ++ ["--disable-shared"];

          buildPhase = ''
            runHook preBuild
            make lib/libraw.la lib/libraw_r.la
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/lib $out/include/libraw
            install -m644 lib/.libs/libraw.a   $out/lib/libraw.a
            install -m644 lib/.libs/libraw_r.a $out/lib/libraw_r.a
            cp -r libraw/. $out/include/libraw/
            runHook postInstall
          '';
        });

        giflibStatic = pkgs.giflib.overrideAttrs (old: {
          makeFlags = (old.makeFlags or []) ++ ["SHAREDLIB="];
          installPhase = ''
            runHook preInstall
            install -Dm644 libgif.a  $out/lib/libgif.a
            install -Dm644 gif_lib.h $out/include/gif_lib.h
            runHook postInstall
          '';
        });

        # ── Pre-fetched assets that `go generate` would download ───────────────
        xtermJs = pkgs.fetchurl {
          url = "https://cdnjs.cloudflare.com/ajax/libs/xterm/3.12.2/xterm.js";
          hash = "sha256-kmKnFnK+yIhGOrAALLJbBXQml6qPraKPLHz41N8KFvM=";
        };
        xtermFitJs = pkgs.fetchurl {
          url = "https://cdnjs.cloudflare.com/ajax/libs/xterm/3.12.2/addons/fit/fit.js";
          hash = "sha256-NJ84uZRKbjotj1hgHNwdEuqkJXgrcaycw7RMRHwZ4lc=";
        };
        xtermCss = pkgs.fetchurl {
          url = "https://cdnjs.cloudflare.com/ajax/libs/xterm/3.12.2/xterm.css";
          hash = "sha256-4NJwjyaTn7Tik3/1e0Ueyr512PH3kx/o7oyEDM2Xo7E=";
        };
        stbImageH = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/nothings/stb/5736b15f7ea0ffb08dd38af21067c314d6a3aae9/stb_image.h";
          hash = "sha256-OOCMHFq4hpro1gXdrvqFrT/qJKKWT9Y6CZwMD3nHC8w=";
        };

        # ── package ────────────────────────────────────────────────────────────
        filestash = pkgs.buildGoModule rec {
          pname = "filestash";
          version = "unstable-2026-07-24";

          src = pkgs.fetchFromGitHub {
            owner = "mickael-kerjean";
            repo = "filestash";
            rev = "581f986dca97a38e4ba084c26ff6803489d909b3";
            hash = "sha256-CyIGhDgM8pn87xqK2AQX5lrHFDRoLLsCMvYKuOOO9og=";
          };

          proxyVendor = true;
          vendorHash = "sha256-cjrPxgUwWNX27/wNYM63aY9/H6Puxs7XNyO3nTZRPBM=";

          env.CGO_ENABLED = "1";
          buildFlags = ["--tags" "fts5"];

          nativeBuildInputs = with pkgs; [pkg-config];

          buildInputs = with pkgs; [
            # Dynamic libs (-lfoo)
            vips
            brotli
            sqlite
            ffmpeg
            lcms2
            glib
            gobject-introspection
            # Static libs (-l:libfoo.a)
            giflibStatic
            libjpegStatic
            libpngStatic
            zlibStatic
            libwebpStatic
            librawStatic
          ];

          preBuild = ''
            cat > server/common/constants_generated.go << 'EOF'
            package common

            func init() {
                BUILD_REF  = "581f986dca97a38e4ba084c26ff6803489d909b3"
                BUILD_DATE = "20260724"
            }
            EOF

            (cd server/generator && go run mime.go)

            mkdir -p server/plugin/plg_handler_console/src
            cat ${xtermJs} ${xtermFitJs} \
              > server/plugin/plg_handler_console/src/xterm.js
            cp ${xtermCss} \
               server/plugin/plg_handler_console/src/xterm.css

            mkdir -p server/plugin/plg_widget_console/assets/vendor
            cat ${xtermJs} ${xtermFitJs} \
              > server/plugin/plg_widget_console/assets/vendor/xterm.js
            cp ${xtermCss} \
               server/plugin/plg_widget_console/assets/vendor/xterm.css

            cp ${stbImageH} server/plugin/plg_image_c/image_psd_vendor.h
          '';

          subPackages = ["cmd"];

          postInstall = ''
            mv $out/bin/cmd $out/bin/filestash
          '';

          meta = with pkgs.lib; {
            description = "Universal file storage client (FTP, SFTP, S3, SMB, WebDAV, …)";
            homepage = "https://www.filestash.app/";
            license = licenses.agpl3Only;
            maintainers = [];
            mainProgram = "filestash";
            platforms = platforms.linux;
          };
        };

        # ── NixOS module ───────────────────────────────────────────────────────
        nixosModule = {
          config,
          lib,
          pkgs,
          ...
        }: let
          cfg = config.services.filestash;
        in {
          options.services.filestash = {
            enable = lib.mkEnableOption "Filestash file manager";
            package = lib.mkOption {
              type = lib.types.package;
              default = filestash;
              description = "The filestash package to use.";
            };
            port = lib.mkOption {
              type = lib.types.port;
              default = 8334;
            };
            dataDir = lib.mkOption {
              type = lib.types.path;
              default = "/var/lib/filestash";
            };
            user = lib.mkOption {
              type = lib.types.str;
              default = "filestash";
            };
            group = lib.mkOption {
              type = lib.types.str;
              default = "filestash";
            };
            openFirewall = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
          };

          config = lib.mkIf cfg.enable {
            users.users.${cfg.user} = {
              isSystemUser = true;
              group = cfg.group;
              home = cfg.dataDir;
              createHome = false;
            };
            users.groups.${cfg.group} = {};

            systemd.tmpfiles.rules = [
              "d '${cfg.dataDir}'      0750 ${cfg.user} ${cfg.group} - -"
              "d '${cfg.dataDir}/data' 0750 ${cfg.user} ${cfg.group} - -"
            ];

            systemd.services.filestash = {
              description = "Filestash file manager";
              wantedBy = ["multi-user.target"];
              after = ["network.target"];
              environment = {
                PORT = toString cfg.port;
                CONFIG_DIR = "${cfg.dataDir}/data";
              };
              serviceConfig = {
                ExecStart = "${cfg.package}/bin/filestash";
                WorkingDirectory = cfg.dataDir;
                User = cfg.user;
                Group = cfg.group;
                Restart = "on-failure";
                RestartSec = "5s";
                NoNewPrivileges = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                ReadWritePaths = [cfg.dataDir];
                PrivateTmp = true;
                PrivateDevices = true;
                ProtectKernelTunables = true;
                ProtectControlGroups = true;
                RestrictNamespaces = true;
                LockPersonality = true;
                MemoryDenyWriteExecute = false;
                RestrictRealtime = true;
                RestrictSUIDSGID = true;
              };
            };

            networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];
          };
        };
      in {
        packages = {
          inherit filestash;
          default = filestash;
        };
        nixosModules = {
          inherit nixosModule;
          default = nixosModule;
        };
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            pkg-config
            vips
            brotli
            sqlite
            ffmpeg
            lcms2
            glib
            gobject-introspection
            giflibStatic
            libjpegStatic
            libpngStatic
            zlibStatic
            libwebpStatic
            librawStatic
          ];
        };
      }
    );
}
