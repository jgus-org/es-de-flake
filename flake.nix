{
  description = "ES-DE (EmulationStation Desktop Edition), an emulator frontend built from its upstream GitLab releases against a pinned freeimage-for-es-de build.";

  inputs = {
    flake-lib.url = "github:jgus-org/flake-lib/v1";
    flake-utils.url = "github:numtide/flake-utils";
    freeimage-for-es-de = {
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:jgus-org/freeimage-for-es-de-flake";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    {
      self,
      flake-lib,
      flake-utils,
      freeimage-for-es-de,
      nixpkgs,
    }:
    let
      pin = import ./pin.nix;
      source = {
        owner = "es-de";
        repo = "emulationstation-de";
        track = "release";
        type = "gitlab";
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib stdenv;

        orgFormatting = flake-lib.lib.mkFormatting {
          inherit self system;
        };

        es-de = stdenv.mkDerivation (finalAttrs: {
          inherit (pin) version;
          buildInputs =
            (with pkgs; [
              alsa-lib
              bluez
              curl
              ffmpeg
              freetype
              harfbuzz
              icu
              libgit2
              libGL
              poppler
              pugixml
              SDL2
            ])
            ++ [ freeimage-for-es-de.packages.${system}.freeimage-for-es-de ];
          cmakeFlags = [ (lib.cmakeBool "APPLICATION_UPDATER" false) ];
          meta = {
            description = "Emulator frontend for browsing and launching games from a unified interface";
            homepage = "https://es-de.org";
            license = lib.licenses.mit;
            mainProgram = "es-de";
            platforms = lib.platforms.linux;
          };
          nativeBuildInputs = with pkgs; [
            cmake
            gettext
            pkg-config
          ];
          pname = "emulationstation-de";
          # GET_PREREQUISITES runs the host's ldd against the poppler library to bake its prerequisites in; it fails under the sandbox and is unneeded.
          postPatch = ''
            substituteInPlace CMake/Packages/FindPoppler.cmake \
              --replace-fail 'GET_PREREQUISITES("''${POPPLER_LIBRARY}" POPPLER_PREREQS 1 0 "" "")' ""
          '';
          src = pkgs.fetchgit {
            fetchSubmodules = false;
            hash = pin.sourceHash;
            rev = pin.sourceRev;
            url = "https://gitlab.com/${source.owner}/${source.repo}.git";
          };
        });

        # A UserThemeDirectory containing a variant of the theme bundled with this exact ES-DE build.
        modern-es-de-covers =
          pkgs.runCommand "es-de-user-themes"
            {
              nativeBuildInputs = [
                pkgs.patch
                pkgs.python3
              ];
            }
            ''
              install -d "$out/modern-es-de-covers"
              cp -r --no-preserve=mode ${es-de}/share/es-de/themes/modern-es-de/. "$out/modern-es-de-covers/"
              cd "$out/modern-es-de-covers"
              patch --fuzz=0 -p1 < ${./modern-es-de-covers.patch}
              python ${./check-modern-theme.py} ${es-de}/share/es-de/themes/modern-es-de "$PWD"
            '';

        updateVersion = flake-lib.lib.mkUpdateVersion {
          inherit pkgs source;
        };
      in
      {
        checks = {
          formatting = orgFormatting.check;
          modern-es-de-covers = modern-es-de-covers;
        };
        formatter = orgFormatting.formatter;
        packages = {
          inherit es-de modern-es-de-covers;
          default = es-de;
          update-branches = flake-lib.lib.mkUpdateBranches {
            inherit pkgs source;
            pinSchema = "github";
          };
          update-version = pkgs.writeShellApplication {
            name = "update-version";
            runtimeInputs = [ pkgs.nix ];
            text = ''
              ${lib.getExe updateVersion} "$@"
              # The shared updater only evaluates when the source is unchanged; verify theme compatibility on that path too.
              nix build --no-link "''${FLAKE_ROOT:-$PWD}#modern-es-de-covers"
            '';
          };
        };
      }
    );
}
