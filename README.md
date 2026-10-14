# ES-DE

Builds [ES-DE](https://es-de.org) (EmulationStation Desktop Edition), a frontend for browsing and launching games from one interface, from its upstream GitLab releases.

It is built against a pinned FreeImageRe rather than classic FreeImage, which is why the flake carries one patch adapting ES-DE's image calls to that API.

## Outputs

| Output | Contents |
|---|---|
| `packages.<system>.es-de` | `es-de`, the frontend |
| `packages.<system>.default` | The same build |
| `packages.<system>.modern-es-de-covers` | A `UserThemeDirectory` of cover variants derived from the theme bundled with this exact build |
| `packages.<system>.update-version` | Rewrites `pin.nix` for a chosen upstream release and verifies the theme artifact |
| `packages.<system>.update-branches` | Ensures one exact branch per tracked release |
| `checks.<system>.modern-es-de-covers` | The same theme artifact, as a check |

## Pinning

`pin.nix` records the ES-DE release built here: `version`, `sourceRev`, `sourceHash`. It is regenerated, never hand-edited. `nix run .#update-version` resolves releases from `es-de/emulationstation-de` on GitLab and rewrites the pin; pass a version explicitly — `nix run .#update-version -- 3.4.1` — when you want the release you chose rather than the newest one listed.

The updater does more than the shared one it wraps: it builds `modern-es-de-covers` afterwards whether or not the pin moved. A new release can change the theme it ships without changing anything the updater would otherwise build, and the derived covers artifact is the thing that notices.

The FreeImageRe build it links is not in `pin.nix`. It is a flake input that follows a branch of the `freeimage-re` producer flake, declared in `flake.nix`, and `flake.lock` records the commit that branch resolved to — so an ES-DE release does not move FreeImageRe, and a FreeImageRe bump does not change which ES-DE is built.

## Versions are branches

Each tracked release gets an exact branch (`v3.4.1`) whose tip is the commit pinning that release. Published branches are never moved or deleted, so depending on `v3.4.1` gives a build that cannot drift.

Alongside them are aggregate pointers — `v3.4`, `v3.5`, `v3`, and `main` — each force-pushed to the highest exact branch that matches, so the default branch follows upstream and a shorter ref tracks the line you named. A branch is only created for a line that has a tracked release in it: with `3.4.1` as the oldest release tracked, there is a `v3.4` and nothing below it.

`nix run .#update-branches` reconciles the branches with upstream. It needs `MINIMUM_TRACKING_VERSION` in the environment, which the scheduled workflow supplies.
