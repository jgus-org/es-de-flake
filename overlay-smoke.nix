# The deliverable is `overlays.default`, so nothing in `packages` realizes what this flake deploys:
# `flake-lib`'s gate builds these copies, throws them away, and publishes nothing from them. The
# theme election is the target that earns its build: it patches the theme bundle taken from the
# installed `es-de`, so it fails when the installed bundle no longer matches the patch and the
# check beside it re-validates the result.
#
# The permit below belongs to the package set this harness builds and to no consumer's. This flake
# takes no licence on anyone's behalf; `README.md` still states that the set running ES-DE carries
# its own allowance. See "Build what an overlay produces" in flake-lib's README.
{
  packages = [
    "es-de"
    "modern-es-de-covers"
  ];
  unfreeFor = [
    "emulationstation-de"
    "es-de-user-themes"
  ];
}
