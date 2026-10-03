# GSE Reference — DEMO_DIABOLIST (Demonology Warlock, Diabolist, Midnight)

Working notes compiled from the gse.tools help pages, applied to the sequences in this folder.
GSE version assumed: **3.3+** (Midnight). WeakAuras is not available in Midnight.

> **Source-verified corrections (GSE repo `cfc7e5cf`, 2026-10-01).** These override anything below that conflicts:
> - **GSE 3 has no KeyPress / KeyRelease.** `GSE.CompileTemplate` compiles only `Versions[n].Actions`; KeyPress/KeyRelease survive only as legacy import keys and are never run. Every line that should fire on each press (`/targetenemy`, `/petattack`, `/use 13`, re-summon) must be written into each Action's `macro` text, and the **255-char limit is per Action**.
> - **`=` lines:** a macro line starting with `=` is evaluated as Lua at compile time (`GSE.CompileMacroText`); its string result replaces the line, and an empty result drops it. The env exposes GSE's private namespace (`GSE.inArena`, `GSE.PVPFlag`, `GSE.V.*`).
> - **Context versions:** `MetaData.Arena`, `.PVP`, `.Raid`, `.Dungeon` … hold a version index; GSE picks it automatically (`GSE.GetActiveVersion`). `GSE.inArena` = instance type `"arena"`.
> - **If block** `Variable` is a Lua expression string (e.g. `GSE.inArena` or `GSE.V.Name()`); true → branch `[1]`, false → `[2]`.
> - **GSEVersion gate:** sequences need `MetaData.GSEVersion` (`major*1000+minor*100+patch`). GSE refuses imports `<= 3200` or newer than installed, and on load disables sequences older than `floor(installed/100)*100`.
> - **Third-party addons** can only reach `_G.GSE.RegisterAddon`, `GetSequenceNamesFromLibrary`, `isEmpty`. See `CLAUDE.md` → GSE Integration Reference.

---

## 1. Files in this folder

| File | What it is |
|---|---|
| `Demo_Diabolist_GSE.lua` | **Compiled template** of a 5-action **Priority** Loop (see §2). Not an import string. |
| `Demo_Diabolist_GSE.txt` | Hand-build instructions for a different design: KeyPress → 13-action Priority Loop → KeyRelease. **Outdated:** GSE 3 doesn't run KeyPress/KeyRelease; fold those lines into each Action. |
| `GSE_Reference.md` | This file. |

Neither file can be uploaded to gse.tools as-is. Build the sequence in-game (`/gse`), then share via the in-game export string, the site's Import tool, or the GSE Companion app.

---

## 2. Analysis of the two designs

### 2a. `.lua` — compiled 5-action Priority loop (recommended base)

The 15 steps follow the Priority pattern `1 / 12 / 123 / 1234 / 12345`, matching the `blockPath` values.

| Action | blockPath | Steps / 15 | Share |
|---|---|---|---|
| Single-Button Assistant (+ `/targetenemy [dead]`, `/petattack`) | 1.1 | 5 | 33% |
| Call Dreadstalkers | 1.2 | 4 | 27% |
| Summon Vilefiend | 1.3 | 3 | 20% |
| `/use [combat] 14` + Summon Demonic Tyrant | 1.4 | 2 | 13% |
| Grimoire: Fel Ravager | 1.5 | 1 | 7% |

- Full cycle = 15 presses ≈ **3.75 s at 250 ms**. Tyrant is attempted roughly every ~2 s.
- Dreadstalkers and Vilefiend sit above Tyrant, so they still tend to land first.
- Longest step ≈ 80 characters (limit 255).

### 2b. `.txt` — 13-action Priority loop

One full cycle = 1+2+…+13 = **91 presses ≈ 23 s at 250 ms**. Action *k* is attempted (14 − k) times per cycle.

| Spell | Positions | Attempts / 91 | Share |
|---|---|---|---|
| Hand of Gul'dan | 2, 6, 10 | 24 | 26% |
| Shadow Bolt | 5, 8, 13 | 16 | 18% |
| Call Dreadstalkers | 1 | 13 | 14% |
| Demonbolt | 4, 12 | 12 | 13% |
| Summon Vilefiend | 3 | 11 | 12% |
| Power Siphon | 7 | 7 | 8% |
| Grimoire: Fel Ravager | 9 | 5 | 5% |
| **Summon Demonic Tyrant** | 11 | 3 | **3%** |

**Problem:** Tyrant is only tried on passes 11–13 of each ~23 s cycle → it can sit off cooldown for up to ~20 s.

Fixes, best first:
1. **Shift-for-Tyrant** — remove Tyrant from the loop; add `/cast [mod:shift] Summon Demonic Tyrant` to the top of every Action's macro (GSE 3 has no KeyPress; see §7). *For this project Tyrant lives on the separate Burst button instead.*
2. Move Tyrant to position 4–5 (~10% of presses; may fire before demons are out).
3. Shorten the loop — use a **Repeat** block for Hand of Gul'dan / Shadow Bolt instead of listing them 3× each (see §4).

> **User's build (2026-10-03):** Summon Vilefiend is **not castable** (drop it), Grimoire is **Imp Lord** (not Fel Ravager), class CC is **Howl of Terror** (not Shadowfury), trinket on-use is **slot 13**. The tables above describe the original files, not the target design.

### Diabolist notes
- Hand of Gul'dan → **Ruination** and Shadow Bolt → **Infernal Bolt** during procs. Blizzard swaps these server-side, so the same `/cast` lines fire them.
- Felguard: Felstorm via `/use Felstorm` (user-verified); Axe Toss on a manual key.
- Defensives (Unending Resolve, Dark Pact, Mortal Coil, Howl of Terror, Circle/Gateway) on their own binds, plus a dedicated Defensive sequence.

---

## 3. Step functions (Loop blocks)

**Sequential** (default): 1, 2, 3, … in order.

**Priority**: restart from the top with one more line each pass.
```
1
12
123
1234
...
```
Line 1 of an *n*-line loop is attempted *n* times as often as line *n*. Closest thing to true priority in WoW.

**Reverse Priority**: same idea, reversed — last line weighted most.
```
1
21
321
4321
...
```
Not useful for this sequence unless the list is flipped (which gives the same result as Priority).

**Key point:** GSE advances one step on **every press**, whether the cast succeeds or not. Presses during the GCD are wasted, so with 4–5 presses per GCD the real cast order is a *weighted lottery*, not strict priority. Failed casts (Demonbolt with no Demonic Core, Hand of Gul'dan with < 3 shards) just move on.

---

## 4. GSE 3.3 block types

| Block | Purpose |
|---|---|
| **Action** | Macro commands for this click. `Type` = GSE block type; `type` = SecureActionButton type (macro, spell, item, toy, pet ability). Non-macro types need a Unit Name (player, target, focus…). |
| **Repeat** | An Action inserted every *n* steps inside its container (and child loops/Ifs, not parents). |
| **Pause** | Wait *n* clicks, *n* ms, or `"GCD"`. Counts clicks — needs the *External MS* option set to your press rate, and you must keep pressing. |
| **Loop** | Contains blocks; has `Repeat` count and `StepFunction`. Loops can nest. Replaces GSE2 Pre/PostMacro. |
| **If** | True/False branches chosen by `Variable`, a Lua expression string (e.g. `GSE.inArena`). Only evaluated on recompile (zone, combat end, PvP flag, instance change, target change since 3.1.38) — **cannot react mid-fight**. |
| **Embed** | Inserts another sequence's compiled version (class sequences searched first, then global). |

Repeat example — `x` with Interval 2 in a 6-line sequence compiles to: `1 x 2 3 x 4 5 x`.

Pause examples:
```lua
{ ['Type'] = 'Pause', ['MS'] = 3000 }   -- 3 seconds
{ ['Type'] = 'Pause', ['Clicks'] = 3 }  -- 3 clicks
{ ['Type'] = 'Pause', ['MS'] = "GCD" }  -- one GCD
```

Ideas for this sequence:
- **Repeat** Hand of Gul'dan (Interval ~3) instead of duplicating it → shorter loop, faster Tyrant.
- **Embed** a shared cooldown sequence into single-target and AoE versions. (Implosion isn't castable on the user's build.)
- **Arena-only behaviour:** prefer an `=GSE.V.<Name>()` macro line or `MetaData.Arena` version over duplicated If branches.

---

## 5. /castsequence — avoid in this sequence

- A castsequence only advances when the **current** spell succeeds. Otherwise it sticks.
- In GSE, a castsequence line advances once per *visit*, not per press.
- **Generator + spender on one line sticks** (e.g. `Shadow Bolt, Hand of Gul'dan` waits for 3 shards).
- **Demonbolt** in a castsequence sticks without a Demonic Core proc.
- `reset=<seconds>` **does not work in GSE** — any cast from any block resets the timer.
- "Once per target" trick (`/castsequence reset=target A, B, null`) is unreliable — the fake name can resolve to a real GCD spell and lock the stack.
- Blizzard's castsequence is buggy; "if you need it to work, don't use a castsequence."

Only plausible use here: `/castsequence reset=combat Call Dreadstalkers, Summon Vilefiend, Summon Demonic Tyrant` to force order — but it stalls when cooldowns drift. **Recommendation: plain `/cast` lines only.**

---

## 6. WoW rules GSE must follow

- **One GCD attempt per hardware event.** The first GCD ability whose conditionals pass is the only one processed — even if it fails. Non-GCD lines (`/targetenemy`, `/petattack`, `/use 13/14`) can be stacked freely.
- **255-character limit** per Action macro (GSE 3 has no KeyPress/KeyRelease, so per-press lines count against every Action).
- A macro cannot `/click` a button that has macrotext.
- GSE cannot invent macro commands or conditionals.
- The sequence is **fixed once combat starts**; it only recompiles on zone, combat end, target change out of combat, PvP/instance changes.
- GSE is not automation: it sends the current step and moves on; the server decides what casts.
- **Press rate:** the "~250 ms" is *your* press rate. Mouse-wheel binding is allowed (each notch = one hardware event). **Auto-clickers / key-repeat tools violate Blizzard's EULA** (§1.C.ii.1).

Verification rule: per-press lines (`/targetenemy`, `/petattack`, `/use 13`, `[nopet] Fel Domination`) are non-GCD; each Action must contain at most one *reachable* GCD cast per press (a `[nopet] Summon Felguard` line takes the GCD only when the pet is dead).

---

## 7. Keybinds vs Button Bindings

**Recommended: Keybind** the sequence directly.

1. `/gse` → KeyBinding → *Set Key to Bind* → press key → choose `DEMO_DIABOLIST`. Leave it on *All talent loadouts* (always set a spec-level default even if you use loadout-specific binds).
2. Also bind **Shift+key** to the same sequence (for Shift-Tyrant).
3. Troubleshooting tab: **Use Multiclick Buttons = ON** for Keybind mode (OFF for Button Bindings).
4. Verify modifiers: enable the mod-tracking option on the Troubleshooting tab, `/reload`, press Shift+key, check chat, then disable and `/reload`.

**Shift + number-key trap:** default WoW binds Shift+1…6 to action-bar paging, so Shift+2 pages your bar instead of firing Tyrant. Use a non-number key (Q, E, F, mouse button / wheel), or unbind Shift+*n* in WoW.

**Sky Riding / vehicles** (only if bound to 1–7) — add to every Action's macro (no KeyPress in GSE 3), must live in the sequence itself:
```
/click [flying][vehicleui][overridebar][possessbar] ActionButton2
```
Use `/fstack` to find the button name for ElvUI/Bartender/etc. Costs ~70 of 255 characters.

Override-bar vehicles: `/click [overridebar] OverrideActionBarButton1`.

**Button Bindings** (alternative): right-click an action-bar slot → choose the sequence. Shows the icon on the bar; works with standard bars, ElvUI, NDui, Bartender4, Dominos, ConsolePort, EllesmereUI. If it doesn't fire:
```
/run SetBindingClick("2", "ActionButton2", _G["ActionButton2"])
/run SaveBindings(1)
```
(`SaveBindings(2)` = per character.)

Controllers: `/console GamePadEnable 1`; Xbox A/B/X/Y = PAD1/2/3/4.

Useful commands:
```
/run GSE_C.KeyBindings = {}        -- clear all keybinds (relog after)
/run GSE_C.ActionBarBinds = {}     -- clear all button bindings (relog after)
/run GSE.ReloadKeyBindings()       -- reload keybinds
```

---

## 8. ActionButtonUseKeyDown CVar

**GSE 3.3+: no longer matters.** Keybinds and Button Bindings fire one step on either key edge. Since 3.1.19 GSE auto-adjusts `/click` lines to the CVar.

If the sequence **cycles without casting** (icon changes, nothing casts): `/gse` → Options → Troubleshooting → **Update Macro Stubs**, or toggle the CVar / force KeyUp or KeyDown mode there.

---

## 9. Chaining macros

An Action block of type **Macro** can call an ordinary `/macro` by name (requires Keybind mode). The called macro **cannot `/click`** anything, so the Sky Riding line must stay in the sequence.

Possible use: put `/use [combat] 14` + `/cast Summon Demonic Tyrant` in a `/macro` named e.g. `DD_Tyrant` to tweak trinkets without opening the GSE editor. Same 255-char limit. Not needed for the current design.

---

## 10. Tracking a sequence (addon, not WeakAuras)

GSE sends two AceEvent messages:
- `GSE_SEQUENCE_ICON_UPDATE` — every click; payload: sequence name + a subset of SpellInfo (`name`, `iconID`, …).
- `GSE_MODS_VISIBLE` — sequence name + table of modifiers seen (Alt/Ctrl/Shift).

Build a small addon that depends on `GSE_Utils` in its `.toc` and registers via `AceEvent:RegisterMessage`. Reference implementation: `GSE_Utils/Tracker.lua` in the GSE-Advanced-Macro-Compiler repo (issue #1835). Verify callback arguments there — the help page's WA example has typos (`GSE_SEQUENCE_ICON_UPDTE`, `SoD_Ret` vs `SoD_RET`).

Uses for DEMO_DIABOLIST: show current-step icon; count per-spell casts per fight to verify the share tables in §2; confirm Shift is registering.

Troubleshooting: if the tracker fires but nothing casts → binding/paging problem; if it doesn't fire → keybinding problem.

---

## 11. Outdated — do not use

**"Creating Addon Packs"** (GS-Core, `Interface: 70100`, `GSImportLegacyMacroCollections`, `GSDisableSequence`) is from Legion / GnomeSequencer 1.x. These APIs don't exist in GSE 3.

---

## 12. Addon options worth knowing (`/gse` → Options)

- Hide login message / minimap icon
- Default import action (merge or replace)
- **External MS** — your press interval in ms; only used for Pause-block timing math. Does not press anything for you.
- Troubleshooting tab: Use Multiclick Buttons, mod-key tracking, Update Macro Stubs, force KeyUp/KeyDown
- Debug output — shows each step as it fires

---

## 13. gse.tools site (FAQ)

- Addon: CurseForge, Wago, or gse.tools/releases → `_retail_/Interface/AddOns/`.
- Browse sequences: gse.tools/sequences (filter Warlock → Demonology).
- No account needed to download public content; account needed to upload or use Companion.
- **Subscriber content** is gated by the author (guild roster, Patreon tier). The site sells nothing.
- **GSE Companion**: desktop app that syncs sequences between the site and your addon.
- Bugs/features: GSE Discord, GitHub, gse.tools/contact-us.

---

## 14. Next steps

Project next steps live in `CLAUDE.md`. Design direction: four buttons (single-target, burst, AoE, defensive), shipped by the `JJJ_GSE_WARLOCK` addon as a GSE COLLECTION via `RegisterAddon`.

- [ ] Optional: tracker addon to verify cast shares in real fights.
