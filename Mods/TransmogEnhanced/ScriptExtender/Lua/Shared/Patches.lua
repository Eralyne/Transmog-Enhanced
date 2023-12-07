---@diagnostic disable: undefined-global

-- Fix improper persistant var storage of Control Items from versions < 1.0.2
-- Old: PersistentVars["ControlItems"][uuid] = character
-- New: PersistentVars["ControlItems"] = { uuid }
function Patches.FixControlItemsPersistantVars()
    local replaceTable = {}

    for k, _ in pairs(PersistentVars["ControlItems"]) do
        if type(k) == "string" then
            table.insert(replaceTable, Utils.GetGUID(k))
        end
    end

    if (Utils.Size(replaceTable) > 0) then
        Utils.Info("Applying v1.0.2 FixControlItemsPersistantVars patch...")

        PersistentVars["ControlItems"] = {}

        for _, val in ipairs(replaceTable) do
            table.insert(PersistentVars["ControlItems"], val)
        end
    end
end
