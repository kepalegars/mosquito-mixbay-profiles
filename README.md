# mosquito mixbay profiles

Community interface profiles for **mosquitomixbay**, the mosquitOmarchy USB-audio
control bay. One folder per card, no executable code: Mixbay downloads only the
card you select, validates it, and deploys it atomically.

`index.json` is the entry point. Every card lives in `<folder>/<id>/card.json`.
Most sit directly under `cards/`; devices that share one integration are
grouped, e.g. `cards/rme/` for every supported RME Fireface.

## Layout

```
index.json                 list of cards (id, version, path, sha256)
schema/card.schema.json    profile schema, validated by CI
cards/<id>/card.json        spec + capabilities + UI layout
cards/rme/<id>/card.json    RME CC-mode cards, one shared oscmix integration
cards/<id>/captures/        distilled JSONL captures (optional)
cards/rme/NOTES.md          what the RME cards share (oscmix, CC mode)
```

Heavy raw USB sessions are **not** stored here. They stay as release
artifacts referenced by `sha256` from a card's `captures` list.

## Card format

A card is data only: `spec` describes the hardware and its capabilities, `ui`
picks a block preset. No shell, no udev rule, no PipeWire install, no USB
replay. Imported profiles never overwrite a native card — natives are embedded
in Mixbay and only your local overrides apply to them.

```json
{
  "schema_version": 1,
  "spec": { "id": "evo8", "display": "Audient EVO 8", "...": "..." },
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

## Contributing a card

1. Reverse-engineer or map the card with `mixbay-reverse`.
2. Write `cards/<id>/card.json` against `schema/card.schema.json`.
3. Run `mosquito-mixbay-actions profiles-validate cards/<id>/card.json`.
4. Add the card to `index.json` with its sha256 (`sha256sum`).
5. Open a PR. CI validates the schema, the digest, and that no executable
   file or device-specific path is included.

Captures you add are distilled JSONL only (one JSON object per line, bus/dev
and serial numbers removed). The raw capture bundle belongs in a release
asset, never in git.

## Licensing

Profiles are data describing hardware you own. Do not include vendor binaries,
firmware, or code copied from vendor software.
