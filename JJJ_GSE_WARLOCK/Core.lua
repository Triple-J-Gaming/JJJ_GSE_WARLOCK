-- JJJ_GSE_WARLOCK: Demonology Warlock PvP sequences delivered to GSE.
--
-- GSE integration (verified against GSE source cfc7e5cf, see CLAUDE.md):
--   * GSE's namespace is private. The global `GSE` is a locked proxy exposing
--     only RegisterAddon, GetSequenceNamesFromLibrary and isEmpty.
--   * GSE.RegisterAddon(name, version, sequencenames, sequencetable) imports
--     sequencetable on first load or when `version` changes. The importer
--     (ImportSerialisedSequence) lives in GSE_Utils, hence both dependencies
--     in the .toc.
--   * Imported sequences need MetaData.GSEVersion matching the installed GSE,
--     or GSE refuses or disables them. GetInstalledGSEVersion() provides it.

local addon_name, ns = ...

local CHAT_PREFIX = "|cFF9482C9JJJ GSE Warlock:|r "

-- GSE versions below this are pre-3.3 and lack the blocks and APIs we rely on.
local MIN_GSE_VERSION = 3300

ns.gse_ready = false

function ns.Print(message)
    print(CHAT_PREFIX .. tostring(message))
end

-- Mirrors GSE.ParseVersion (GSE/API/Init.lua): "3.3.12-xyz" -> 3*1000 + 3*100 + 12.
-- Returns nil when the string can't be parsed, e.g. an unpackaged GSE source
-- checkout reports the literal "@project-version@".
function ns.ParseGSEVersion(version_string)
    if type(version_string) ~= "string" then
        return nil
    end
    local major, minor, patch = version_string:match("^(%d+)%.(%d+)%.(%d+)")
    if not major then
        return nil
    end
    return tonumber(major) * 1000 + tonumber(minor) * 100 + tonumber(patch)
end

-- The installed GSE version as GSE itself would number it (MetaData.GSEVersion).
function ns.GetInstalledGSEVersion()
    local version_string = C_AddOns.GetAddOnMetadata("GSE", "Version")
    return ns.ParseGSEVersion(version_string), version_string
end

-- Checks that GSE is loaded and exposes what we need. Returns true/false and
-- prints a single clear chat message on failure. Never errors.
function ns.CheckGSE()
    local gse_api = _G.GSE
    if type(gse_api) ~= "table" or type(gse_api.RegisterAddon) ~= "function" then
        ns.Print("GSE is not loaded, or its plugin API is missing. Sequences were not installed.")
        return false
    end

    local _, utils_loaded = C_AddOns.IsAddOnLoaded("GSE_Utils")
    if not utils_loaded then
        ns.Print("GSE_Utils is not loaded. Enable it in the AddOns list; GSE needs it to import sequences.")
        return false
    end

    local version_number, version_string = ns.GetInstalledGSEVersion()
    if not version_number then
        ns.Print("Could not read the GSE version (" .. tostring(version_string) .. "). Sequences were not installed.")
        return false
    end
    if version_number < MIN_GSE_VERSION then
        ns.Print("GSE " .. version_string .. " is too old. GSE 3.3 or newer is required.")
        return false
    end

    return true
end

local event_frame = CreateFrame("Frame")
event_frame:RegisterEvent("PLAYER_LOGIN")
event_frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        -- PLAYER_LOGIN: every addon and its SavedVariables (incl. GSEOptions,
        -- which RegisterAddon writes to) are loaded by now.
        ns.gse_ready = ns.CheckGSE()
        if ns.gse_ready then
            local _, version_string = ns.GetInstalledGSEVersion()
            ns.Print("Loaded. GSE " .. version_string .. " detected.")
            -- Sequence registration (GSE.RegisterAddon) is added in the next step.
        end
    end
end)
