{
  description = "ES-DE (EmulationStation Desktop Edition), an emulator frontend built from its upstream GitLab releases against a pinned freeimage-for-es-de build.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-lib = {
      url = "github:jgus-org/flake-lib/v1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    freeimage-for-es-de = {
      url = "github:jgus-org/freeimage-for-es-de-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
      flake-lib,
      freeimage-for-es-de,
    }:
    let
      pin = import ./pin.nix;
      source = {
        type = "gitlab";
        owner = "es-de";
        repo = "emulationstation-de";
        track = "release";
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib stdenv;

        treefmtEval = treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
        };

        es-de = stdenv.mkDerivation (finalAttrs: {
          pname = "emulationstation-de";
          inherit (pin) version;

          src = pkgs.fetchgit {
            url = "https://gitlab.com/${source.owner}/${source.repo}.git";
            rev = pin.sourceRev;
            hash = pin.sourceHash;
            fetchSubmodules = false;
          };

          # GET_PREREQUISITES runs the host's ldd against the poppler library to bake its prerequisites in; it fails under the sandbox and is unneeded.
          postPatch = ''
            substituteInPlace CMake/Packages/FindPoppler.cmake \
              --replace-fail 'GET_PREREQUISITES("''${POPPLER_LIBRARY}" POPPLER_PREREQS 1 0 "" "")' ""
          '';

          nativeBuildInputs = with pkgs; [
            cmake
            gettext
            pkg-config
          ];

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
            platforms = lib.platforms.linux;
            mainProgram = "es-de";
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
          buildAttr = "modern-es-de-covers";
          verification = "build";
        };
      in
      {
        formatter = treefmtEval.config.build.wrapper;

        checks.formatting = treefmtEval.config.build.check self;
        checks.modern-es-de-covers = modern-es-de-covers;
        packages = {
          inherit es-de modern-es-de-covers;
          default = es-de;
          update-version = pkgs.writeShellApplication {
            name = "update-version";
            runtimeInputs = [ pkgs.nix ];
            text = ''
              ${lib.getExe updateVersion} "$@"
              # The shared updater only evaluates when the source is unchanged; verify theme compatibility on that path too.
              nix build --no-link "''${FLAKE_ROOT:-$PWD}#modern-es-de-covers"
            '';
          };
          update-branches = flake-lib.lib.mkUpdateBranches {
            inherit pkgs source;
            pinSchema = "github";
          };
        };
      }
    );
}
