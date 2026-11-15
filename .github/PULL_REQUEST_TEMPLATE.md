## Interface profile

- Card id:
- Hardware / vendor:
- Backend (`alsa`, `evo-raw`, `douze`, `auto`):
- What is mapped (volumes, mutes, gains, 48V, mixer, meters):
- What stays hardware-only:

## Checklist

- [ ] `bash scripts/validate.sh` passes
- [ ] `mosquito-mixbay-actions profiles-validate cards/<id>/card.json` passes
- [ ] no serial number / bus / device path / username
- [ ] no executable code, firmware or install script inside `cards/` (integrations live in `integrations/`, hashed in `index.json`)
- [ ] captures (if any) are distilled JSONL
- [ ] native cards are not overwritten by this PR
