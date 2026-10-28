# es-de

A Nix flake that builds [ES-DE](https://es-de.org) (EmulationStation Desktop Edition), the frontend for browsing and launching a game collection from one interface.

## Outputs

| Attribute          | What you get                                                                        |
| ------------------ | ----------------------------------------------------------------------------------- |
| `overlays.default` | Adds `es-de` and `modern-es-de-covers` to the nixpkgs package set it is applied to. |

## Consuming

Apply the overlay to the package set that runs ES-DE — the set whose `nixpkgs.config` already decides what unfree software this machine installs — and take the two attributes from it. On NixOS that is the machine's own set, so the overlay goes in `nixpkgs.overlays` and no second package set is built:

```nix
nixpkgs.overlays = [ es-de.overlays.default ];
# …and `pkgs.es-de` beside the packages the rest of the configuration takes from `pkgs`.
```

A consumer with no package set of its own instantiates one:

```nix
pkgs = import nixpkgs {
  inherit system;
  config.allowUnfree = true;
  overlays = [ es-de.overlays.default ];
};
```

`nixpkgs.config.allowUnfreePredicate` matching these two packages takes the allowance just as well. The instantiating set is the one that grants it; this flake takes none, so nixpkgs refuses to evaluate either package in a set that permits no unfree packages.

- `pkgs.es-de` is `bin/es-de` with its data under `share/es-de`, including the themes it ships.
- `pkgs.modern-es-de-covers` is a user theme directory holding one theme, `modern-es-de-covers`, listed in ES-DE as **Modern (box art)**: the bundled Modern theme with the game image preferring box art and falling back to a screenshot.

Published for `x86_64-linux` and `aarch64-linux`; ES-DE itself builds for Linux only.

## Requirements and notes

- ES-DE takes the machine over: it runs fullscreen under SDL2, needs a display server, and reads controllers from `/dev/input`. It is not usable headless.
- Configuration, collections and gamelist metadata live in the user's ES-DE directory, `~/.config/emulationstation-de` by default. Emulators and ROM paths are yours to declare; the build ships no controller configuration or game metadata.
- The application updater is not compiled in: this build performs no update check and offers none.
- To use the theme variant, set ES-DE's `UserThemeDirectory` to the path of `modern-es-de-covers` and choose `modern-es-de-covers` as the theme. It is derived from the themes of this exact ES-DE build and verified against nothing else, so take the two from the same revision.

See [LICENSE.md](LICENSE.md) for licensing and copyright, and [NOTICE.md](NOTICE.md) for the terms of upstream and distributed artifacts.
