# Sequence Design — JJJ_GSE_WARLOCK (Demonology Diabolist, PvP)

v1 (finalized 2026-10-03). This is the design. The addon will turn these into GSE sequences.
Rules come from `CLAUDE.md` and `GSE_Reference.md` (source-verified header).

## Shared pieces

### Variable `JJJ_AutoTarget`
```lua
function() if GSE.inArena then return "" end return "/targetenemy [noharm][dead]" end
```
Outside arena this compiles to `/targetenemy [noharm][dead]`, which picks a new enemy only when you have no living hostile target. Inside arena the line disappears. It re-evaluates on zone/instance change.

### Damage prefix (top of every Action in buttons 1–3)
```
/cast [nopet] Fel Domination
=GSE.V.JJJ_AutoTarget()
/petattack
/cast [nopet] Summon Felguard
```
Order is forced by GSE: a macro must **start with `/`** to be treated as macro text, and one starting with `=` is evaluated whole as Lua. So the `=` line can't be first.
All lines are off the GCD except `Summon Felguard`, which only fires when the pet is gone (it then takes that press's GCD attempt, by design). The prefix is 94 chars as authored and 98 compiled. Longest compiled step per button (measured in a Lua 5.1 harness): ST 127, BURST 144, AOE 141, DEF 31 (limit 255).

## Button 1 — `JJJ_ST` (single-target damage)

Priority loop, 4 actions, so the attempt ratio is 4:3:2:1 per 10 presses.

| # | Action line (after prefix) | Why here |
|---|---|---|
| 1 | `/cast Single-Button Assistant` | Blizzard's helper picks Shadow Bolt / Demonbolt-on-Core / Ruination / Infernal Bolt correctly; GSE can't see shards or procs. |
| 2 | `/cast Call Dreadstalkers` | On cooldown. Fails fast when not ready. |
| 3 | `/cast Hand of Gul'dan` | Main spender (3 shards). Fails without shards. |
| 4 | `/cast Power Siphon` | Converts imps to Demonic Cores. Low weight. |

Trinket: `/use [combat] 13` is **not** in this button. It's saved for the Burst button (see Open choice A).

## Button 2 — `JJJ_BURST` (go button)

Priority loop, 5 actions. Every Action also carries `/use [combat] 13` (Badge of Ferocity, off the GCD).

| # | Action line | Note |
|---|---|---|
| 1 | `/cast Call Dreadstalkers` | Guide burst order step 1. |
| 2 | `/cast Grimoire: Imp Lord` | Step 2, in-combat summon. |
| 3 | `/cast Summon Demonic Tyrant` | Step 3. Has a cast time; extra presses during the cast just fail. |
| 4 | `/cast Hand of Gul'dan` | Dump shards. |
| 5 | `/cast Single-Button Assistant` | Filler / Demonbolt on Core. |

Once the cooldowns are spent their lines fail instantly, so the button falls through to HoG and SBA. Press it for the whole kill window.

## Button 3 — `JJJ_AOE` (multi-target / battlegrounds)

No Implosion on this build. AoE comes from Felstorm, Wild Imps (HoG), and Dreadstalkers.
Every Action also carries `/use Felstorm` (pet ability, user-verified syntax, off the player's GCD), so Felstorm fires whenever it's ready.

| # | Action line | |
|---|---|---|
| 1 | `/cast Hand of Gul'dan` | Imps are the AoE. |
| 2 | `/cast Call Dreadstalkers` | |
| 3 | `/cast Single-Button Assistant` | |
| 4 | `/cast Power Siphon` | |

## Button 4 — `JJJ_DEF` (defensive)

No damage prefix (no auto-target or pet attack). **Sequential** loop, so each press escalates one step:

| Press | Action | |
|---|---|---|
| 1 | `/cast Dark Pact` | Cheapest (45s with Frequent Donor). |
| 2 | `/cast Soulburn` + `/use Healthstone` | Soulburn-empowered stone (heal + temp max HP). |
| 3 | `/cast Unending Resolve` | Biggest CD (40% DR + interrupt immunity). |

Pressing 3 times in a row uses all three. A press on something on cooldown does nothing and still advances. Demonic Circle: Teleport stays manual, because auto-teleporting is too risky.

## Verified in-game (2026-10-03)
- Dark Pact, Soulburn, Unending Resolve are **off the GCD**.
- `/use Healthstone` and `/cast Single-Button Assistant` work by name.
- Defensive order approved as drafted.

## Decisions
- **Trinket:** Burst only (`/use [combat] 13`). The user didn't object; revisit if they want it on single-target too.
- **Defensive:** stays Sequential (one escalation step per press), even though all three are off the GCD and *could* fire on one press. The user approved escalation.
