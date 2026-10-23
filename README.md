# ES-DE

A Nix flake that builds [ES-DE](https://es-de.org) (EmulationStation Desktop Edition), a frontend for browsing and launching games from one unified interface, from its upstream GitLab releases. ES-DE is not packaged in nixpkgs.

```sh
nix run github:jgus-org/es-de-flake
```

## Outputs

| Output                                  | Contents                                                                                                                                                                                                                                     |
| --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `packages.<system>.es-de`               | The frontend                                                                                                                                                                                                                                 |
| `packages.<system>.default`             | The same build                                                                                                                                                                                                                               |
| `packages.<system>.modern-es-de-covers` | A `UserThemeDirectory` built from the `Modern` theme shipped with this exact build: renamed `Modern (box art)`, with its artwork view reading `cover, screenshot` so box art takes precedence and a screenshot serves when a system has none |
| `packages.<system>.update-version`      | Rewrites `pin.nix` for a chosen upstream release and verifies the theme artifact                                                                                                                                                             |
| `packages.<system>.update-branches`     | Ensures one exact branch per tracked release                                                                                                                                                                                                 |
| `checks.<system>.modern-es-de-covers`   | The same theme artifact, as a check                                                                                                                                                                                                          |

`es-de` is built with upstream's application updater disabled, so upgrades come from the flake rather than from the running frontend.

## Image loading

ES-DE loads images through a FreeImage 3 compatible library. This flake links [freeimage-for-es-de](https://github.com/jgus-org/freeimage-for-es-de-flake), a clean-room MIT-licensed reimplementation of the API subset ES-DE uses, which needs no patch against ES-DE. Which build of it gets linked is recorded in `flake.lock` rather than in `pin.nix`: the input follows that flake's default branch, so an ES-DE release does not move the image library and an image library bump does not change which ES-DE is built.

## Pinning

`pin.nix` records the ES-DE release built here: `version`, `sourceRev`, `sourceHash`. It is regenerated, never hand-edited. `nix run .#update-version` resolves releases from `es-de/emulationstation-de` on GitLab and rewrites the pin; pass a version explicitly — `nix run .#update-version -- 3.4.1` — when you want the release you chose rather than the newest one listed.

The updater does more than the shared one it wraps: it builds `modern-es-de-covers` afterwards whether or not the pin moved. A new release can change the theme it ships without changing anything the updater would otherwise build, and the derived covers artifact is the thing that notices.

## Versions are branches

Each tracked release gets an exact branch (`v3.4.1`) whose tip is the commit pinning that release. Published branches are never moved or deleted, so depending on `v3.4.1` gives a build that cannot drift.

Alongside them are aggregate pointers — `v3.4`, `v3`, and `main` — each force-pushed to the highest exact branch that matches, so the default branch follows upstream and a shorter ref tracks the line you named. A branch exists only for a line that has a tracked release in it.

```nix
{
  inputs.es-de.url = "github:jgus-org/es-de-flake/v3.4";
}
```
