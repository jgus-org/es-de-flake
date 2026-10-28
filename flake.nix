{
  description = "ES-DE (EmulationStation Desktop Edition); absent from nixpkgs. Built against the freeimage-for-es-de flake.";

  inputs = {
    flake-lib.url = "github:jgus-org/flake-lib/v1";
    freeimage-for-es-de = {
      inputs = {
        flake-lib.follows = "flake-lib";
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
    flake-lib.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        orgFormatting = flake-lib.lib.mkFormatting {
          inherit self system;
        };
      in
      {
        checks.formatting = orgFormatting.check;
        formatter = orgFormatting.formatter;
        packages = {
          # Nothing published here is a package anyone should install: `overlays.default` is the
          # interface, and the derivations in it cannot be instantiated in this flake at all
          # without an unfree allowance. This target exists because `update-version` evaluates
          # `packages.default` on every run and the branch publisher builds it.
          #TODO remove this
          default = pkgs.emptyDirectory;
          update-branches = flake-lib.lib.mkUpdateBranches {
            inherit pkgs source;
            minimumTrackingVersion = "3.4.0";
            pinSchema = "github";
          };
          update-version = flake-lib.lib.mkUpdateVersion {
            inherit pkgs source;
          };
        };
      }
    )
    // {
      # What this flake publishes is built here and instantiated there. ES-DE installs the Modern
      # and Slate themes beside its MIT source, so an election that describes the output is
      # unfree, and nixpkgs refuses to instantiate it at all without a permit. This flake takes
      # none: the consumer's package set is the one that grants the allowance and resolves the
      # build, exactly as it does for every other unfree package it installs.
      overlays.default = final: _prev: rec {
        es-de = final.stdenv.mkDerivation (finalAttrs: {
          inherit (pin) version;
          buildInputs =
            (with final; [
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
            ++ [ freeimage-for-es-de.packages.${final.stdenv.hostPlatform.system}.freeimage-for-es-de ];
          cmakeFlags = [ (final.lib.cmakeBool "APPLICATION_UPDATER" false) ];
          meta = {
            description = "Emulator frontend for browsing and launching games from a unified interface";
            homepage = "https://es-de.org";
            license = with final.lib.licenses; [
              mit
              cc-by-nc-sa-40
            ];
            mainProgram = "es-de";
            platforms = final.lib.platforms.linux;
          };
          nativeBuildInputs = with final; [
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
          src = final.fetchgit {
            fetchSubmodules = false;
            hash = pin.sourceHash;
            rev = pin.sourceRev;
            url = "https://gitlab.com/${source.owner}/${source.repo}.git";
          };
        });

        # A UserThemeDirectory containing a variant of the theme bundled with this exact ES-DE build.
        modern-es-de-covers =
          final.runCommand "es-de-user-themes"
            {
              meta.license = final.lib.licenses.cc-by-nc-sa-40;
              nativeBuildInputs = [
                final.patch
                final.python3
              ];
            }
            ''
              install -d "$out/modern-es-de-covers"
              cp -r --no-preserve=mode ${es-de}/share/es-de/themes/modern-es-de/. "$out/modern-es-de-covers/"
              cd "$out/modern-es-de-covers"
              patch --fuzz=0 -p1 < ${./modern-es-de-covers.patch}
              python ${./check-modern-theme.py} ${es-de}/share/es-de/themes/modern-es-de "$PWD"
            '';
      };
    };
}
