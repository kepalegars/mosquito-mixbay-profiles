# mosquito mixbay profiles

Community interface profiles for **mosquitomixbay**, the mosquitOmarchy USB-audio
control bay. One folder per card: Mixbay downloads only the card you select,
validates it, and deploys it atomically. Cards are data; the few installers a
card may request by name live in `integrations/` and are pinned file by file
in `index.json`.

`index.json` is the entry point. Every card lives in `<folder>/<id>/card.json`.
Most sit directly under `cards/`; devices that share one integration are
grouped, e.g. `cards/rme/` for every supported RME Fireface.

## Layout

```
index.json                 list of cards + integrations (id, version, path, sha256)
schema/card.schema.json    profile schema, validated by CI
cards/<id>/card.json        spec + capabilities + UI layout
cards/rme/<id>/card.json    RME CC-mode cards, one shared oscmix integration
cards/<id>/captures/        distilled JSONL captures (optional)
cards/rme/NOTES.md          what the RME cards share (oscmix, CC mode)
integrations/oscmix/        installer + GTK/Qt launchers (RME profiles)
integrations/evo-raw/       evo_raw kmod + capture helper (EVO profiles)
```

Heavy raw USB sessions are **not** stored here. They stay as release
artifacts referenced by `sha256` from a card's `captures` list.

## Card format

A card is data only: `spec` describes the hardware and its capabilities, `ui`
picks a block preset. No shell, no udev rule, no PipeWire install, no USB
replay. `spec.setup` may name one closed integration (`oscmix`, `evo-raw`,
`douze`); the files themselves come from `integrations/` and are verified
against the index. Every card is a normal install: nothing is privileged, and
anything can be uninstalled and installed again.

```json
{
  "schema_version": 1,
  "spec": {
    "id": "evo8", "display": "Audient EVO 8", "...": "...",
    "setup": "evo-raw"
  },
  "credits": { "author": "mosquito", "contributors": ["@someone"] },
  "ui": { "preset": "evo8", "blocks": ["tabBar", "controlsGrid"] },
  "captures": []
}
```

`credits.author` is shown in Mixbay's profile info popup. Cards made inside
mosquitOmarchy credit `mosquito`; add every outside contributor to
`credits.contributors`.

Presets: `evo8`, `evo4`, `ugm192`, `single-pair`, `auto`. A local
`~/.config/mosquitomixbay/cards/<id>/user/layout.json` can override any `ui`
key (objects merge, arrays replace) without touching the profile.

## Integrations

`spec.setup` selects, by name, the tooling a card needs:

| name | files | used by |
|------|-------|---------|
| `oscmix` | engine build + GTK/Qt launchers | every RME Fireface |
| `evo-raw` | evo_raw kmod + 8-channel capture helper | EVO 8 / EVO 4 |
| `douze` | shipped by mosquitOmarchy (SSL 12) | SSL 12 |

Mixbay downloads an integration into
`~/.local/share/mosquitomixbay/integrations/<name>/`, checks each file's
sha256 from `index.json`, then runs its installer. Nothing is installed until
a profile that needs it is installed, and uninstalling the last card that uses
it removes the shared tool. The integration scripts are the only executable
files in this repo, and they live outside `cards/`.

## Direct RME updates (`spec.upstream`)

RME cards can declare an `upstream` URL pointing at their own `card.json` in
this repository:

```json
"upstream": "https://raw.githubusercontent.com/kepalegars/mosquito-mixbay-profiles/main/cards/rme/fireface-802/card.json"
```

When `r` checks the repo, Mixbay also fetches that URL. If it is newer than
the installed card, the update is offered with a warning: it is not part of
the published index yet, comes directly from this repo, and may be slightly
ahead of the Mixbay build. Uninstall + reinstall is the way back. The URL is
pinned to this repository's raw host; a card cannot point elsewhere.

## Contributing a card

1. Reverse-engineer or map the card with `mixbay-reverse`.
2. Write `cards/<id>/card.json` against `schema/card.schema.json`.
3. Run `mosquito-mixbay-actions profiles-validate cards/<id>/card.json`.
4. Add the card to `index.json` with its sha256 (`sha256sum`).
5. Open a PR. CI validates the schema, the digest, and that no executable
   file or device-specific path is included.
6. A new integration (`integrations/<name>/`) must also be listed in
   `index.json` with every file's sha256; CI refuses unlisted files and any
   executable inside `cards/`.

Captures you add are distilled JSONL only (one JSON object per line, bus/dev
and serial numbers removed). The raw capture bundle belongs in a release
asset, never in git.

## Licensing

Profiles are data describing hardware you own. Do not include vendor binaries,
firmware, or code copied from vendor software.
