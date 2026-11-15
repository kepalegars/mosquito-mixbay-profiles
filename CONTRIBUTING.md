# Contributing a profile

One card per folder: `cards/<id>/card.json`, validated by
`schema/card.schema.json`. The fastest path is to generate it from a machine
that owns the hardware:

```bash
mosquito-mixbay-actions profiles-export <id> --to /tmp/export
# review /tmp/export, then copy cards/<id>/ and the index row into your fork
bash scripts/validate.sh
```

Rules:

- data only — no executable, firmware, udev rule or install script;
- no serial number, USB bus/device path, hostname or local path;
- a native card is never replaced by a PR: changes to `evo8`, `evo4`,
  `ugm192`, `ssl12` or `fireface-ucx2` must be coordinated with a Mixbay
  release, because the built-in copy is what ships;
- captures are distilled JSONL (one object per line); raw sessions go in a
  release asset referenced by sha256;
- update the `sha256` in `index.json` when the card changes.

## UI presets

`ui.preset` selects a block composition: `evo8`, `evo4`, `ugm192`,
`single-pair` or `auto`. `ui.blocks` documents which reusable blocks the card
uses (`tabBar`, `controlsGrid`, `controlsSingle`, `mixerGrid`,
`levelsColumns`, `statusBar`, `help`). Users can override any `ui` key locally
with a sparse `user/layout.json`; arrays replace, objects merge.

Adding a preset is a Mixbay change, not a data change. Until then use `auto`.
