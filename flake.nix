{
  description = "Niri: A scrollable-tiling Wayland compositor (SHORiN-KiWATA fork).";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    shorin-niri = {
      url = "github:SHORiN-KiWATA/niri";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      shorin-niri,
    }:
    let
      revision = self.shortRev or self.dirtyShortRev or "unknown";
      niri-package =
        {
          lib,
          cairo,
          dbus,
          libGL,
          libdisplay-info,
          libinput,
          seatd,
          libxkbcommon,
          libgbm,
          pango,
          pipewire,
          pkg-config,
          rustPlatform,
          systemd,
          wayland,
          installShellFiles,
          withDbus ? true,
          withSystemd ? true,
          withScreencastSupport ? true,
          withDinit ? false,
        }:

        rustPlatform.buildRustPackage {
          pname = "niri";
          version = revision;

          src = shorin-niri;

          postPatch = ''
            patchShebangs resources/niri-session
            substituteInPlace resources/niri.service \
              --replace-fail 'ExecStart=niri' "ExecStart=$out/bin/niri"
          '';

          cargoLock = {
            allowBuiltinFetchGit = true;
            lockFile = "${shorin-niri}/Cargo.lock";
          };

          strictDeps = true;

          nativeBuildInputs = [
            rustPlatform.bindgenHook
            pkg-config
            installShellFiles
          ];

          buildInputs =
            [
              cairo
              dbus
              libGL
              libdisplay-info
              libinput
              seatd
              libxkbcommon
              libgbm
              pango
              wayland
            ]
            ++ lib.optional (withDbus || withScreencastSupport || withSystemd) dbus
            ++ lib.optional withScreencastSupport pipewire
            ++ lib.optional withSystemd systemd;

          buildFeatures =
            lib.optional withDbus "dbus"
            ++ lib.optional withDinit "dinit"
            ++ lib.optional withScreencastSupport "xdp-gnome-screencast"
            ++ lib.optional withSystemd "systemd";
          buildNoDefaultFeatures = true;

          preCheck = ''
            export XDG_RUNTIME_DIR="$(mktemp -d)"
          '';

          checkFlags = [
            "--skip=::egl"
          ];

          postInstall =
            ''
              installShellCompletion --cmd niri \
                --bash <($out/bin/niri completions bash) \
                --fish <($out/bin/niri completions fish) \
                --nushell <($out/bin/niri completions nushell) \
                --zsh <($out/bin/niri completions zsh)

              install -Dm644 resources/niri.desktop -t $out/share/wayland-sessions
              install -Dm644 resources/niri-portals.conf -t $out/share/xdg-desktop-portal
            ''
            + lib.optionalString withSystemd ''
              install -Dm755 resources/niri-session $out/bin/niri-session
              install -Dm644 resources/niri{.service,-shutdown.target} -t $out/lib/systemd/user
            '';

          env = {
            RUSTFLAGS = toString (
              map (arg: "-C link-arg=" + arg) [
                "-Wl,--push-state,--no-as-needed"
                "-lEGL"
                "-lwayland-client"
                "-Wl,--pop-state"
              ]
            );
            NIRI_BUILD_COMMIT = revision;
          };

          passthru = {
            providedSessions = [ "niri" ];
          };

          meta = {
            description = "Scrollable-tiling Wayland compositor (SHORiN-KiWATA fork)";
            homepage = "https://github.com/SHORiN-KiWATA/niri";
            license = lib.licenses.gpl3Only;
            mainProgram = "niri";
            platforms = lib.platforms.linux;
          };
        };

      inherit (nixpkgs) lib;
      systems = lib.intersectLists lib.systems.flakeExposed lib.platforms.linux;

      forAllSystems = lib.genAttrs systems;
      nixpkgsFor = forAllSystems (system: nixpkgs.legacyPackages.${system});
    in
    {
      checks = forAllSystems (system: {
        inherit (self.packages.${system}) niri-debug;
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          rustfmt' = pkgs.rustfmt.override { asNightly = true; };
          inherit (self.packages.${system}) niri;
        in
        {
          default = pkgs.mkShell {
            packages = builtins.attrValues {
              inherit (pkgs)
                rustc
                cargo
                clippy
                cargo-insta
                ;
              inherit rustfmt';
            };

            nativeBuildInputs = [
              pkgs.rustPlatform.bindgenHook
              pkgs.pkg-config
              pkgs.wrapGAppsHook4
            ];

            buildInputs = niri.buildInputs ++ [
              pkgs.libadwaita
            ];

            env = {
              RUSTFLAGS = niri.RUSTFLAGS;
            };
          };
        }
      );

      formatter = forAllSystems (system: nixpkgsFor.${system}.nixfmt-rfc-style);

      packages = forAllSystems (
        system:
        let
          niri = nixpkgsFor.${system}.callPackage niri-package { };
        in
        {
          inherit niri;

          niri-debug = niri.overrideAttrs (
            newAttrs: oldAttrs: {
              pname = oldAttrs.pname + "-debug";

              cargoBuildType = "debug";
              cargoCheckType = newAttrs.cargoBuildType;

              dontStrip = true;
            }
          );

          default = niri;
        }
      );

      overlays.default = final: _: {
        niri = final.callPackage niri-package { };
      };
    };
}
