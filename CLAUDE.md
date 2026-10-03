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
| `Sequence_Design.md` | **Finalized v1** design of the four buttons (ST, BURST, AOE, DEF), with char budgets. Source for the addon's sequence data. |
| `JJJ_GSE_WARLOCK/` | The addon. `Core.lua` = namespace, chat print, GSE checks, version parsing. |
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
- **Public API surface (verified, GSE source `cfc7e5cf`, 2026-10-01):** GSE's namespace is addon-private. The global `_G.GSE` is a locked proxy exposing **only** `RegisterAddon`, `GetSequenceNamesFromLibrary`, `isEmpty` (`GSE/API/Plugins.lua`). `AddSequenceToCollection`, `ReplaceSequence`, `UpdateVariable`, `ImportSerialisedSequence`, `EncodeMessage` are internal — **not callable** from our addon.
  - `GSE.RegisterAddon(name, version, sequencenames, sequencetable)`: on first load or when `version` changes, GSE runs `ImportSerialisedSequence(entry, false)` on each `sequencetable` entry, then reloads sequences. Collisions with existing sequences show GSE's import dialog (not force-replaced).
  - An entry can be an import string or a table: `{name, sequence}`, or `{type = "COLLECTION", payload = {Sequences = {[name] = seq}, Variables = {[name] = var}, Macros = {...}}}` — so variables can ship inside a COLLECTION.
  - `ImportSerialisedSequence` lives in `GSE_Utils`, so our `.toc` should declare `## Dependencies: GSE, GSE_Utils` to guarantee load order.
- **Export string format (verified, `GSE/API/Serialisation.lua`):** `"!GSE3!" .. C_EncodingUtil.EncodeBase64(C_EncodingUtil.CompressString(C_EncodingUtil.SerializeCBOR(tab)))`, where a sequence export's `tab` is `{sequenceName, sequence}`. `!GSE3!+` is the sealed gse.tools format — never produce it. Sequence table schema (`MetaData`, `Versions`, …): **needs verification** from `GSE/API/Storage.lua` / `spec/` before generating sequences.
- **Sequence table schema (verified, `spec/sequencechecker_spec.lua`, `GSE/API/Storage.lua`):**
  ```lua
  { MetaData = { Name, SpecID = 266, ClassID = 9, Default = 1, Arena = <ver>, GSEVersion = <n>, Author, Notes },
    Versions = { [1] = { Actions = { ...blocks... }, InbuiltVariables = {} } } }
  ```
  - Blocks: `{Type="Action", macro="/cast X
/cast Y"}`; `{Type="Loop", Repeat="1", StepFunction=<Priority|Sequential>, ...blocks}`; `{Type="If", Variable="<lua expr>", [1]={...true blocks}, [2]={...false blocks}}`; `Repeat` uses `Interval`; `Pause` uses `Clicks` or `MS`.
  - **No KeyPress/KeyRelease in GSE 3.** `GSE.CompileTemplate` compiles only `Version.Actions`; KeyPress/KeyRelease appear only as legacy import keys. Lines meant to run on every press (pet attack, re-summon, trinket, auto-target) must go inside each Action's `macro` text. The 255-char budget is per Action macro. `GSE_Reference.md` has been corrected to match (2026-10-03).
  - Old sequences are blocked. Import rejects `GSEVersion <= 3200` or `> installed`, and on load (retail) GSE **disables** sequences whose `GSEVersion < floor(installed/100)*100`. Our addon must stamp `MetaData.GSEVersion` from `C_AddOns.GetAddOnMetadata("GSE","Version")` parsed as `major*1000 + minor*100 + patch` (`GSE.ParseVersion`).
  - Ship via `RegisterAddon` as a **COLLECTION** so imports run with `skipDialogs`. A single sequence with no checksum triggers GSE's integrity confirm dialog.
- **Macro-text Lua evaluation (verified, `GSE.CompileMacroText`):** any macro line starting with `=` is evaluated as Lua at compile time, in an env where `GSE` is the private namespace (so `GSE.inArena`, `GSE.PVPFlag`, `GSE.V.*` work). The result replaces the line; empty lines are dropped. Recompile happens on zone/instance change.
- **Arena flag (verified, `GSE/API/Events.lua`):** `GSE.inArena = (instanceType == "arena")`. Sequences can also pick a version per context natively: `MetaData.Arena = <version index>` (`GSE.GetActiveVersion`).
- **GSE Variables (verified):** `{ MetaData = {Name, Default=1}, Versions = { [1] = { funct = "function() ... end" } } }`. Compiled as `GSE.V[name] = loadstring("return "..funct)()`; reference in macros as `=GSE.V.Name()` or in an If block's `Variable`.
- **`.toc` (verified):** GSE ships `## Interface: 11509, 16001, 20506, 50504, 120007, 120100` — **12.1 = `120100`**.
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

- **Spec:** Demonology (spec ID 266). Confirmed from the user's loadout string.
- **Hero tree:** Diabolist. Confirmed from the loadout (Wowhead, 2026-10-03). Note: the Demonology PvP guide recommends Soul Harvester; the user plays Diabolist.
- **Talent Build:** Import string:
  `CoQAMrNP5kak+EBqLfUa3dMm+uMmxMjmlZGLMzMLDAAAAAAwYZZGzMDbGGmZb2ahmxiZmZsNLzMzwAAzMGzMzMYmZmZmxsBAAGzwYYMLDDYA`
  Points: Warlock 34/34, Demonology 34/34, Hero 13/13. Talents read from the Wowhead calc DOM (for choice nodes `[c]`, the chosen side: **needs verification** in-game):
  - *Spec tree:* Hand of Gul'dan, Demoniac, Call Dreadstalkers, Fel Intellect, Dreadlash, Imp-erator, Power Siphon [c], Summon Felguard, Infernal Rapidity, Rune of Shadows, Carnivorous Stalkers, Imp Gang Boss, Inner Demons, Summon Demonic Tyrant, Blighted Maw, Tyrant's Oblation, Antoran Armaments, Flametouched, Sacrificed Souls, Reign of Tyranny, Master Summoner, Demonic Calling, Hellbent Commander, Grimoire: Imp Lord [c, confirmed in-game; Wowhead DOM showed Fel Ravager], Summon Vilefiend, Stabilized Portals, Mark of F'harg [c], Dominion of Argus.
  - *Hero tree (Diabolist):* Diabolic Ritual, Cloven Souls, Touch of Rancora, Secrets of the Coven, Diabolic Oculi, Annihilan's Bellow [c], Infernal Machine [c], Infernal Bulwark [c], Looks That Kill, Flames of Xoroth, Abyssal Dominion, Gloom of Nathreza, Mind's Eyes, Ruination.
  - *Class tree:* Fel Domination, Soul Leech, Demon Skin, Fel Armor, Demonic Embrace, Horrify [c], Demonic Fortitude, Curse of Exhaustion, Infernal Beneficiary, Mortal Coil, Pact of the Annihilan, Demonic Circle, Pact of the Satyr, Improved Mortal Coil, Dark Pact, Foul Mouth, Empowered Healthstone, Abyss Walker, Teachings of the Black Harvest, Gorefiend's Avarice, Frequent Donor [c], Pact of the Eredar, Demonic Resilience, Dark Accord [c], Demonic Gateway, Howl of Terror [c, confirmed via spellbook; Wowhead DOM showed Shadowfury], Soul Link, Frequent Traveler, Oppressive Darkness, Pact of Gluttony, Soulburn, Blight of Tongues [c].
- **PvP Talents:** Nether Ward, Call Fel Lord (user said "Summon Fel Lord"; the Demonology PvP guide names it **Call Fel Lord**, so confirm the exact in-game spell name before using it in `/cast`), Gateway Mastery.
  - Nether Ward = 3s spell reflect (vs casters, magical interrupts). Call Fel Lord = melee stun ring (guide suggests swapping it in for Nether Ward vs melee). Gateway Mastery = passive, adds +20yd gateway range and a shorter gateway debuff, so it needs no macro line.
- **Castable spells (user's spellbook, 2026-10-03):**
  - *Demonology:* Call Dreadstalkers, Grimoire: Imp Lord, Power Siphon, Demonbolt, Hand of Gul'dan, Summon Demonic Tyrant.
  - *Warlock:* Axe Toss (Command Demon), Blight of Tongues, Create Healthstone, Create Soulwell, Curse of Exhaustion, Curse of Weakness, Dark Pact, Demonic Circle (+ Teleport), Demonic Gateway, Drain Life, Eye of Kilrogg, Fear, Fel Domination, Howl of Terror, Mortal Coil, Ritual of Doom, Ritual of Summoning, Shadow Bolt, Soulburn, Soulstone, Subjugate Demon, Summon Demon, Unending Breath, Unending Resolve.
  - **Not castable:** Summon Vilefiend, Implosion (no Implosion means the AoE button needs a different spender, so design from this list only). Page 2 of the spellbook (not seen) may hold more.
- **Pets:**
  - **Main pet: Felguard** (Summon Felguard talent, cast via *Summon Demon*). Summon it before combat. Its *Command Demon* ability is **Axe Toss** (stun), which stays on a manual key as CC. **Auto re-summon (decided):** every damage button's Action macros start with (GSE 3 has no KeyPress, see GSE Integration Reference)
    ```
    /cast [nopet] Fel Domination
    /cast [nopet] Summon Felguard
    ```
    With a pet alive, both lines fail their `[nopet]` check and the step's normal action runs. With no pet, Fel Domination fires if it's off cooldown (otherwise the line silently fails), then the summon takes that press's GCD attempt. Budget: ~62 chars of the 255 per Action.
    - **Verified in-game (2026-10-03):** Fel Domination is off the GCD; `/cast Summon Felguard` works by name.
    - **Decided:** the summon is **not** gated on Fel Domination. If it's on cooldown, the button still starts the slow (full cast time) summon.
  - **Grimoire: Imp Lord** is an **in-combat** temporary summon on cooldown. It belongs in the Burst button, not as a resting pet.
  - **Felstorm** works from a macro as **`/use Felstorm`** (user verified in-game; use that exact form, not `/cast`). Use it in the AoE button.
- **Key PvP Abilities:** [LIST PRIORITY ABILITIES AND WHY]
- **Trinkets** (Wowhead tooltips, ilvl 331):
  - Venomous Aspirant's Badge of Ferocity (item 270559): **on-use**, +461 primary stat for 15s, 1 min cooldown. Equipped in **slot 13** (top), so sequences use `/use 13`.
  - Venomous Aspirant's Insignia of Alacrity (item 270558): **passive** proc, chance on spell for +389 primary stat for 20s. No macro line needed.
- **Playstyle Preferences:**
  - **One button per situation.** Four sequences, each on its own key:
    1. **Single-target damage**: main priority loop with `/petattack` (trinket moved to Burst only, see `Sequence_Design.md`).
    2. **Burst / go**: Demonic Tyrant, Grimoire: Imp Lord, Badge of Ferocity (`/use 13`), then a damage dump.
    3. **AoE / multi-target**: for battlegrounds and stacked enemies.
    4. **Defensive**: cycles defensive tools (Dark Pact, healthstone, etc.).
  - Other CC (Nether Ward, Call Fel Lord, Mortal Coil, Howl of Terror, Fear, Axe Toss) stays on manual keys unless the user decides otherwise.
  - **Auto-target outside Arena only.** Include `/targetenemy` (and `/petattack`) everywhere except arenas, where the user picks targets manually.
    - **Implementation (decided, verified against source):** ship a GSE Variable `JJJ_AutoTarget` with `funct = "function() if GSE.inArena then return '' end return '/targetenemy [noharm][dead]' end"`, and start each damage Action's macro with the line `=GSE.V.JJJ_AutoTarget()`. Outside arena it compiles to the targeting line; in arena the line disappears. Updates on zone/instance change. No duplicated If branches or extra versions needed. The exact `/targetenemy` conditionals are still a design choice.
- **Keybinds:** No custom keybinds yet; default WoW binds only. Sequence key, modifier usage and press rate: not chosen yet.
- **Current GSE Sequences:** [LIST SEQUENCES TO IMPORT OR BUILD UPON]
  - *In folder:* `DEMO_DIABOLIST` in two designs (`.lua` 5-action, `.txt` 13-action).

---

## Project State

### Current Status
*Last updated: 2026-10-03 (session 1).*

- Addon scaffold exists: `JJJ_GSE_WARLOCK/` with `.toc` (Interface 120100, deps GSE + GSE_Utils) and `Core.lua` (GSE presence/version check on `PLAYER_LOGIN`). Not yet tested in-game; no Lua toolchain on this machine to syntax-check.
- Reference material is in place: `GSE_Reference.md`, two `DEMO_DIABOLIST` sequence designs, and PvP guides for all three specs.
- `CLAUDE.md` created.
- Git repo set up on GitHub. Root duplicates of the destruction guides removed.
- Addon name chosen: `JJJ_GSE_WARLOCK`.
- GSE source cloned locally to `GSE-Advanced-Macro-Compiler/` (git-ignored). Open Questions 3–5 answered from it.

### Decisions Made
- Plain `/cast` lines over `/castsequence` — castsequences stall when a spell is unavailable and `reset=<seconds>` doesn't work in GSE (`GSE_Reference.md` §5).
- Priority-loop design from `Demo_Diabolist_GSE.lua` preferred over the 13-action `.txt` loop — the `.txt` loop leaves Tyrant at ~3% of presses (`GSE_Reference.md` §2).
- Sequences are authored in-game / via GSE import strings; the addon will not load sequences from raw `.lua` files.
- Addon name is `JJJ_GSE_WARLOCK` (folder, `.toc`, function prefix, SavedVariables).
- Integration path: deliver sequences/variables through `GSE.RegisterAddon` (the only write path GSE exposes to other addons). Bump the version argument to push updates.

### Open Questions
1. ~~**Addon name**~~ Resolved: `JJJ_GSE_WARLOCK`.
2. ~~**Spec and hero tree**~~ Resolved: Demonology Diabolist (user's loadout string).
3. ~~**How can a third-party addon create or modify GSE sequences/variables?**~~ Resolved: only via `GSE.RegisterAddon` (see GSE Integration Reference). Imports run on first load/version change; collisions prompt the user.
4. ~~**GSE import/export string format and sequence schema**~~ Resolved: `!GSE3!` + Base64(Compress(CBOR({name, sequence}))); schema, GSEVersion gate and COLLECTION shipping are in GSE Integration Reference.
5. ~~**`.toc` details**~~ Resolved: `## Interface: 120100`; `## Dependencies: GSE, GSE_Utils`.
6. ~~**Summon Vilefiend in Midnight**~~ Resolved: not in the user's spellbook (screenshot 2026-10-03), so it's passive or merged. Remove every `/cast Summon Vilefiend` line from the sequence designs.
7. ~~**Single-Button Assistant**~~ Resolved: user confirms it works in PvP and inside GSE.
8. ~~**Grimoire: Fel Ravager vs. Grimoire: Imp Lord**~~ Resolved: user has **Grimoire: Imp Lord** (in-game). Existing `DEMO_DIABOLIST` lines casting Fel Ravager must change to Imp Lord.

### Next Steps
1. Load-test the scaffold in-game (link `JJJ_GSE_WARLOCK/` into `World of Warcraft/_retail_/Interface/AddOns/`); expect "Loaded. GSE x.y.z detected." on login.
2. Encode `Sequence_Design.md` v1 as Lua tables (schema in GSE Integration Reference), stamp `GSEVersion`, ship as a COLLECTION via `GSE.RegisterAddon` (variables need `objectType = "VARIABLE"` inside the collection, or GSE treats them as sequences).
3. Test in-game: import, arena/non-arena auto-target, re-summon, per-step char counts.

---

## Session Start Checklist

1. Read this entire `CLAUDE.md`.
2. Confirm **Current Status** reflects reality. If stale, flag it and ask.
3. Review **Warlock Configuration**. If details are missing or need updating, ask before proceeding.
4. Check **Open Questions**. Raise any that block the current task.
5. Start with the top **Next Steps** item unless told otherwise.
6. At session end, update Current Status, Decisions Made, Open Questions, and Next Steps.
