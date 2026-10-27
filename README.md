# es-de

A Nix flake that builds [ES-DE](https://es-de.org) (EmulationStation Desktop Edition), the frontend for browsing and launching a game collection from one interface.

## Outputs

| Attribute                      | What you get                                                                                                                                                                                                |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `packages.default`             | `bin/es-de` with its data under `share/es-de`, including the themes it ships.                                                                                                                               |
| `packages.es-de`               | The same package under its own name.                                                                                                                                                                        |
| `packages.modern-es-de-covers` | A user theme directory holding one theme, `modern-es-de-covers`, listed in ES-DE as **Modern (box art)**: the bundled Modern theme with the game image preferring box art and falling back to a screenshot. |
| `checks.modern-es-de-covers`   | Builds that theme, which is how its fit to this ES-DE version is checked.                                                                                                                                   |

Published for `x86_64-linux` and `aarch64-linux`; ES-DE itself builds for Linux only.

```sh
nix build .#default
nix build .#modern-es-de-covers
```

## Requirements and notes

- ES-DE takes the machine over: it runs fullscreen under SDL2, needs a display server, and reads controllers from `/dev/input`. It is not usable headless.
- Configuration, collections and gamelist metadata live in the user's ES-DE directory, `~/.config/emulationstation-de` by default. Emulators and ROM paths are yours to declare; the build ships no controller configuration or game metadata.
- The application updater is not compiled in: this build performs no update check and offers none.
- To use the theme variant, set ES-DE's `UserThemeDirectory` to the path of `packages.modern-es-de-covers` and choose `modern-es-de-covers` as the theme. It is derived from the themes of this exact ES-DE build and verified against nothing else, so take the two from the same revision.

See [LICENSE.md](LICENSE.md) for licensing and copyright, and [NOTICE.md](NOTICE.md) for the terms of upstream and distributed artifacts.
