# RME (CC mode)

All supported RME cards share one integration: [`huddx01/oscmix`](https://github.com/huddx01/oscmix),
built from a pinned `dev` commit. Mixbay installs the engine (`oscmix`,
`alsaseqio`, `alsarawio`) plus the GTK mixer, and offers the Qt UI as an
optional AppImage.

What the cards in this folder have in common:

- `backend: "alsa"` — Mixbay only probes the card (`/proc/asound/cards`) so it
  knows the interface is there. Every mixer control lives in oscmix.
- `setup: "oscmix"` — the closed set of integrations Mixbay may run. A card is
  data; it never carries a command or a URL.
- every `caps` flag is `false` — the card menu is a flat list of actions, not a
  control surface: **Open GTK mixer**, **Open Qt UI**, **Open web UI**,
  **Set up / repair oscmix**.
- the Qt row is greyed while upstream has no preview AppImage for the current
  nightly (the source is private and the binaries are uploaded by hand); it
  un-greys as soon as the file exists. The web UI (`huddx01.github.io/oscmix`)
  is the frontend that works today: Web MIDI straight to the card, no engine.
- the interface must be in **Class Compliant** mode (`SETUP ▸ Options` on the
  unit). In USB driver mode Linux sees no ALSA card and no MIDI port, so
  nothing can reach it.
- `card_match` fragments are UPPERCASED substrings of the `/proc/asound/cards`
  long name and end in ` at`, so `Fireface UFX II at` cannot be mistaken for
  `Fireface UFX III at`.

`num_inputs` / `num_output_pairs` describe the analog I/O for reference only;
the mixer's real channel count comes from oscmix's device tables.

No card writes to the interface on setup, and no service is installed: the GTK
and Qt frontends start the engine on demand and stop it when they close.
