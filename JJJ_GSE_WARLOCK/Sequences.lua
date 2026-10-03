-- Sequence and variable data for JJJ_GSE_WARLOCK.
-- Design source: Sequence_Design.md v1. Schema: CLAUDE.md -> GSE Integration Reference.
--
-- GSE 3 has no KeyPress/KeyRelease (verified in GSE source), so lines that must
-- run on every press are prepended to each Action's macro text.

local addon_name, ns = ...

local SPEC_ID_DEMONOLOGY = 266
local CLASS_ID_WARLOCK = 9
local AUTHOR = "Triple-J-Gaming"
local MAX_MACRO_CHARS = 255

-- GSE Variable: auto-target everywhere except Arena.
-- GSE compiles funct with `GSE` bound to its private namespace, so GSE.inArena
-- is available (set from the instance type in GSE/API/Events.lua).
local AUTO_TARGET_VARIABLE = "JJJ_AutoTarget"
local AUTO_TARGET_LINE = "/targetenemy [noharm][dead]"
local AUTO_TARGET_FUNCT =
    "function() if GSE.inArena then return '' end return '" .. AUTO_TARGET_LINE .. "' end"

-- Per-press prefix for damage buttons. All lines are off the GCD except
-- Summon Felguard, which only passes [nopet] when the Felguard is gone.
-- Order matters to GSE (verified, GSE/API/Storage.lua buildAction):
--   * the macro must START with "/" or GSE won't treat it as macro text;
--   * a macro starting with "=" is evaluated whole as one Lua expression.
-- So the "=" auto-target line can't come first. It goes before /petattack so
-- the pet attacks the newly picked target.
local DAMAGE_PREFIX = table.concat({
    "/cast [nopet] Fel Domination",
    "=GSE.V." .. AUTO_TARGET_VARIABLE .. "()",
    "/petattack",
    "/cast [nopet] Summon Felguard",
}, "\n")

local TRINKET_LINE = "/use [combat] 13"   -- Badge of Ferocity, slot 13
local FELSTORM_LINE = "/use Felstorm"      -- user-verified syntax

-- Builds one Action block from macro lines.
-- `type = "macro"` is required: GSE 3.3.34's editor (GSE_GUI/Editor.lua) treats
-- an action with no lowercase `type` as new and blanks its macro text. The
-- compiler infers the type, but the editor doesn't.
local function MakeAction(...)
    return { Type = "Action", type = "macro", macro = table.concat({ ... }, "\n") }
end

-- Builds a Loop block holding one Action per entry in action_lines.
-- Every Action gets `prefix` (may be nil) followed by its own line.
local function MakeLoop(step_function, prefix, action_lines)
    local loop = { Type = "Loop", Repeat = "1", StepFunction = step_function }
    for _, line in ipairs(action_lines) do
        if prefix then
            table.insert(loop, MakeAction(prefix, line))
        else
            table.insert(loop, MakeAction(line))
        end
    end
    return loop
end

local function MakeSequence(name, notes, loop, gse_version)
    return {
        MetaData = {
            Name = name,
            SpecID = SPEC_ID_DEMONOLOGY,
            ClassID = CLASS_ID_WARLOCK,
            Default = 1,
            GSEVersion = gse_version,
            -- Client TOC (e.g. 120100). GSE warns "not specifically designed for
            -- this version of the game" on import when this is missing or from
            -- another expansion (GSE.TOCFlavour compares floor(toc / 10000)).
            TOC = select(4, GetBuildInfo()),
            Author = AUTHOR,
            Notes = notes,
        },
        Versions = {
            [1] = { Actions = { loop }, InbuiltVariables = {} },
        },
    }
end

-- Sequence names, in the order shown to GSE.
ns.SEQUENCE_NAMES = { "JJJ_ST", "JJJ_BURST", "JJJ_AOE", "JJJ_DEF" }

-- Returns the COLLECTION table handed to GSE.RegisterAddon.
-- gse_version: the installed GSE version number (MetaData.GSEVersion).
function ns.BuildCollection(gse_version)
    local st_loop = MakeLoop("Priority", DAMAGE_PREFIX, {
        "/cast Single-Button Assistant",
        "/cast Call Dreadstalkers",
        "/cast Hand of Gul'dan",
        "/cast Power Siphon",
    })

    local burst_prefix = DAMAGE_PREFIX .. "\n" .. TRINKET_LINE
    local burst_loop = MakeLoop("Priority", burst_prefix, {
        "/cast Call Dreadstalkers",
        "/cast Grimoire: Imp Lord",
        "/cast Summon Demonic Tyrant",
        "/cast Hand of Gul'dan",
        "/cast Single-Button Assistant",
    })

    local aoe_prefix = DAMAGE_PREFIX .. "\n" .. FELSTORM_LINE
    local aoe_loop = MakeLoop("Priority", aoe_prefix, {
        "/cast Hand of Gul'dan",
        "/cast Call Dreadstalkers",
        "/cast Single-Button Assistant",
        "/cast Power Siphon",
    })

    -- Defensive: no damage prefix; Sequential so each press escalates one step.
    local def_loop = MakeLoop("Sequential", nil, {
        "/cast Dark Pact",
        "/cast Soulburn\n/use Healthstone",
        "/cast Unending Resolve",
    })

    local sequences = {
        JJJ_ST = MakeSequence("JJJ_ST", "Single-target damage (Priority).", st_loop, gse_version),
        JJJ_BURST = MakeSequence("JJJ_BURST", "Burst: Dreadstalkers > Imp Lord > Tyrant > HoG > SBA, trinket.", burst_loop, gse_version),
        JJJ_AOE = MakeSequence("JJJ_AOE", "Multi-target: HoG, Dreadstalkers, SBA, Power Siphon, Felstorm.", aoe_loop, gse_version),
        JJJ_DEF = MakeSequence("JJJ_DEF", "Defensive escalation: Dark Pact > Soulburn+Healthstone > Unending Resolve.", def_loop, gse_version),
    }

    local variables = {
        [AUTO_TARGET_VARIABLE] = {
            -- objectType routes this entry to GSE's variable importer;
            -- without it GSE would treat it as a sequence.
            objectType = "VARIABLE",
            name = AUTO_TARGET_VARIABLE,
            -- Both shapes, so this works on either GSE:
            --   * GSE 3.3.34 (installed) reads a flat top-level `funct` and errors
            --     on nil. That error aborted GSE's whole OOC queue, dropping the
            --     queued sequence saves.
            --   * Newer GSE (repo HEAD) reads Versions[active].funct and leaves an
            --     extra top-level funct alone.
            funct = AUTO_TARGET_FUNCT,
            MetaData = { Name = AUTO_TARGET_VARIABLE, Default = 1, Author = AUTHOR,
                Notes = "Returns the auto-target line outside Arena, nothing inside." },
            Versions = { [1] = { funct = AUTO_TARGET_FUNCT } },
            GSEVersion = gse_version,
        },
    }

    return { type = "COLLECTION", payload = { Sequences = sequences, Variables = variables } }
end

-- Splits the collection into one single-sequence COLLECTION per sequence,
-- keyed by sequence name. GSE's options panel (Plugins → Restore) looks entries
-- up by name, so each sequence can be restored on its own. Damage sequences
-- carry the auto-target variable they reference; JJJ_DEF doesn't need it.
function ns.SplitCollection(collection)
    local entries = {}
    local variables = collection.payload.Variables
    for _, name in ipairs(ns.SEQUENCE_NAMES) do
        local payload = { Sequences = { [name] = collection.payload.Sequences[name] } }
        if name ~= "JJJ_DEF" then
            payload.Variables = variables
        end
        entries[name] = { type = "COLLECTION", payload = payload }
    end
    return entries
end

-- Worst-case compiled length of a macro: the `=GSE.V...` line can expand to
-- AUTO_TARGET_LINE, so measure with that substitution.
local function CompiledLength(macro)
    local expanded = macro:gsub("=GSE%.V%." .. AUTO_TARGET_VARIABLE .. "%(%)", AUTO_TARGET_LINE)
    return #expanded
end

-- Returns a list of problems (empty when every Action fits the 255-char limit).
function ns.ValidateCollection(collection)
    local problems = {}
    for name, sequence in pairs(collection.payload.Sequences) do
        for _, version in ipairs(sequence.Versions) do
            for _, block in ipairs(version.Actions) do
                for index, action in ipairs(block) do
                    local length = CompiledLength(action.macro)
                    if length > MAX_MACRO_CHARS then
                        table.insert(problems, string.format("%s step %d is %d chars (limit %d)",
                            name, index, length, MAX_MACRO_CHARS))
                    end
                end
            end
        end
    end
    return problems
end
