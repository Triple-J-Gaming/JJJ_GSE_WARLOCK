# CLAUDE.md — Warlock PvP GSE Addon

Persistent project brief. Read this first every session; update **Project State** at the end of every session.

---

## Project Overview

**Goal:** Build a World of Warcraft addon that integrates with GSE (Gnome Sequencer Enhanced) to create and manage PvP macros, GSE sequences, and variables for a level 90 Warlock.

**Scope:** The addon depends on GSE and must use its API and data formats rather than reinvent them. Target is PvP play on a single character.

**Language:** WoW addon Lua (retail, Midnight expansion, patch 12.1 — GSE 3.3+ assumed).

**Addon name:** `JJJ_GSE_WARLOCK`. Used for the folder, `.toc`, function prefix, and SavedVariables.

---

## Project Files

| Path | What it is |
|---|---|
| `GSE_Reference.md` | **Primary source** for GSE structure, blocks, constraints, keybinding, and tracker events. |
| `Demo_Diabolist_GSE.lua` | Compiled 15-step output of a 5-action Priority loop (Demonology). Reference only — not an import string. |
| `Demo_Diabolist_GSE.txt` | Hand-build instructions for a 13-action Priority loop (Demonology). Has a known Tyrant-starvation problem (see `GSE_Reference.md` §2b). |
| `Demonology_Warlock_PvP_Guide.md` | Demonology PvP summary (Icy Veins, 12.1). |
| `affliction-warlock/` | Affliction PvP summary (12.1). |
| `destruction-warlock/` | Destruction PvP + PvE guide set (12.1), including PvP macros and talents. |

Git repo: `Triple-J-Gaming/JJJ_GSE_WARLOCK` on GitHub. GSE source is not committed here; in cloud sessions it is cloned read-only to `/home/user/timothyluke/gse-advanced-macro-compiler` (GSE-Advanced-Macro-Compiler).

---

## GSE Integration Reference

`GSE_Reference.md` is the source of truth for sequence structure, API calls, and constraints. Key facts:

- **Sequences:** Built in-game (`/gse`) and shared via GSE's export string, the gse.tools Import tool, or the GSE Companion app. **Not** loaded from `.lua` files directly.
- **Advancement:** GSE advances one step per hardware press, regardless of cast success. Priority loops weight attempts by position: a 5-action loop gives a 5-4-3-2-1 attempt ratio per 15 presses (`1 / 12 / 123 / 1234 / 12345`).
- **Blocks (GSE 3.3):** Action, Repeat, Pause, Loop, If, Embed. If conditions evaluate **on recompilation only** (zone, combat end, PvP flag, instance change, target change out of combat) — never mid-combat.
- **Avoid `/castsequence`.** Use plain `/cast` lines. Castsequences stall on failed casts and `reset=<seconds>` does not work in GSE.
- **Constraints:**
  - One GCD ability attempt per hardware event. Only the first GCD spell whose conditionals pass is processed.
  - 255-character limit across KeyPress + action + KeyRelease combined.
  - Sequences are fixed once combat starts.
  - Non-GCD lines (`/targetenemy`, `/petattack`, `/use 13`/`14`) don't trigger the GCD and can be stacked.
  - A macro cannot `/click` a button that has macrotext. GSE cannot invent macro commands or conditionals.
  - No auto-clickers or key-repeat tools (Blizzard EULA). Mouse-wheel binds are allowed.
- **Documented addon hooks** (`GSE_Reference.md` §10): AceEvent messages `GSE_SEQUENCE_ICON_UPDATE` (every click; sequence name + SpellInfo subset) and `GSE_MODS_VISIBLE` (sequence name + modifiers seen). Reference implementation: `GSE_Utils/Tracker.lua` in the GSE-Advanced-Macro-Compiler repo. **Callback argument shapes: needs verification** against that source.
- **Outdated — never use:** GS-Core addon packs, `GSImportLegacyMacroCollections`, `GSDisableSequence`, `Interface: 70100` (Legion-era, not in GSE 3).

### Rules for integration work

- **Do not invent API calls.** If a GSE function, table, or event isn't in `GSE_Reference.md` or in GSE source in this folder, flag it as an open question and stop.
- Mark any detail you're unsure of as **(needs verification)** before building on it. Check `GSE_Reference.md` first, then GSE source code if added to the folder.
- Spell names and availability must come from the 12.1 guides or in-game data, not memory. Midnight removed/merged several Warlock abilities.

---

## Working Conventions

**Coding style:** Standard WoW Lua. Meaningful names. Comment macro logic, sequence flow, and every GSE integration point (what GSE provides, what we assume, what's verified).

**Addon structure:** Addon folder at project root containing a `.toc` with the same name as the folder. Flat layout unless complexity demands subdirectories. Declare GSE as a required dependency in the `.toc` (exact dependency names and `## Interface:` number for 12.1: **needs verification**).

**Naming:**
- Functions: `PascalCase`, prefixed with the addon name (e.g. `JJJ_GSE_WARLOCK_BuildSequence`) or attached to the addon's namespace table.
- Variables: `snake_case`.
- Constants: `SCREAMING_SNAKE_CASE`.
- No unintended globals — use the addon namespace (`local addon_name, ns = ...`).

**Macro limit handling:** Budget every step against 255 characters across KeyPress + action + KeyRelease. Split long logic into multiple sequences/macros, or compress with Repeat/Loop blocks. Note the character count of the longest step when designing a sequence.

**Code review:** Small, atomic changes. One clear task per commit/session. Make it easy to see what changed and why.

**Error handling and validation:**
- Check that GSE is loaded and the expected version/API exists before calling into it; degrade gracefully with a clear chat message if not.
- Validate user input (types, ranges, nil) before use.
- Defensive nil and type checks on anything read from GSE or SavedVariables.
- Never modify secure state or sequences in combat (`InCombatLockdown()`).

---

## Warlock Configuration

Leave placeholders until confirmed. Level 90 / Midnight abilities differ from older expansions — verify from in-game data or notes, not assumptions.

- **Spec:** [YOUR SPEC HERE]
  - *Evidence in folder, not confirmed:* existing sequences are Demonology (Diabolist); guides exist for all three specs.
- **Hero tree:** [YOUR HERO TREE HERE]
  - *Conflict:* sequences are named Diabolist; the Demonology PvP guide recommends Soul Harvester as the only PvP build.
- **Talent Build:** [YOUR TALENT CHOICES / IMPORT STRING HERE]
- **PvP Talents:** [YOUR 3 PVP TALENTS HERE]
- **Key PvP Abilities:** [LIST PRIORITY ABILITIES AND WHY]
- **Trinkets:** [PRIMARY AND SECONDARY TRINKETS — and whether each is on-use (slot 13/14)]
- **Playstyle Preferences:** [ROTATION STYLE, DEFENSIVE NEEDS, CC PRIORITY, ETC.]
- **Keybinds:** [SEQUENCE KEY, MODIFIER USAGE, PRESS RATE IN MS]
- **Current GSE Sequences:** [LIST SEQUENCES TO IMPORT OR BUILD UPON]
  - *In folder:* `DEMO_DIABOLIST` in two designs (`.lua` 5-action, `.txt` 13-action).

---

## Project State

### Current Status
*Last updated: 2026-10-03 (session 1).*

- No addon code exists yet. No addon folder, `.toc`, or Lua files.
- Reference material is in place: `GSE_Reference.md`, two `DEMO_DIABOLIST` sequence designs, and PvP guides for all three specs.
- `CLAUDE.md` created.
- Git repo set up on GitHub. Root duplicates of the destruction guides removed.
- Addon name chosen: `JJJ_GSE_WARLOCK`.

### Decisions Made
- Plain `/cast` lines over `/castsequence` — castsequences stall when a spell is unavailable and `reset=<seconds>` doesn't work in GSE (`GSE_Reference.md` §5).
- Priority-loop design from `Demo_Diabolist_GSE.lua` preferred over the 13-action `.txt` loop — the `.txt` loop leaves Tyrant at ~3% of presses (`GSE_Reference.md` §2).
- Sequences are authored in-game / via GSE import strings; the addon will not load sequences from raw `.lua` files.
- Addon name is `JJJ_GSE_WARLOCK` (folder, `.toc`, function prefix, SavedVariables).

### Open Questions
1. ~~**Addon name**~~ Resolved: `JJJ_GSE_WARLOCK`.
2. **Spec and hero tree** — Demonology Diabolist (per sequences) vs. Soul Harvester (per PvP guide) vs. another spec. Blocks all sequence design.
3. **How can a third-party addon create or modify GSE sequences/variables?** No create/update API is documented in `GSE_Reference.md`; only tracker events are. Needs GSE source (GSE-Advanced-Macro-Compiler repo) in the folder to verify. Fallback: addon generates import strings or build instructions for the user to paste into GSE. **Blocks core scope.**
4. **GSE import/export string format** — needs verification from GSE source before the addon can produce strings.
5. **`.toc` details** — `## Interface:` number for 12.1 and exact GSE dependency names (`GSE`, `GSE_Utils`?) — needs verification.
6. **Summon Vilefiend in Midnight** — the PvP guide says it can no longer be cast (merged into Call Dreadstalkers), but both existing sequences cast it. Needs in-game verification; likely dead lines.
7. **Single-Button Assistant** — used as filler in the `.lua` design. Confirm it's usable in rated PvP and inside a GSE macro line (needs verification).
8. **Grimoire: Fel Ravager vs. Grimoire: Imp Lord** — sequences use Fel Ravager; the PvP burst rotation uses Imp Lord. Depends on talent build.

### Next Steps
1. Fill in Warlock Configuration (spec, hero tree, talents, trinkets, keybinds).
2. Answer Open Questions 3–5 from the cloned GSE source.
3. Decide the addon's integration approach based on what GSE actually exposes (direct API vs. generated import strings vs. tracker-only).
4. Scaffold the addon folder + `.toc` + core Lua file with GSE presence check.

---

## Session Start Checklist

1. Read this entire `CLAUDE.md`.
2. Confirm **Current Status** reflects reality. If stale, flag it and ask.
3. Review **Warlock Configuration**. If details are missing or need updating, ask before proceeding.
4. Check **Open Questions**. Raise any that block the current task.
5. Start with the top **Next Steps** item unless told otherwise.
6. At session end, update Current Status, Decisions Made, Open Questions, and Next Steps.
