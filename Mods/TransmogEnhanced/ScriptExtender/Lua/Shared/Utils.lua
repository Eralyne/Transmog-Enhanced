---@diagnostic disable: undefined-global

-- Local Functions --

local function protectedSet(old, key, value)
    old[key] = value
end



-- Global Functions --

function Utils.Size(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function Utils.Set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

function Utils.TryGetProxy(entity, proxy)
    return entity[proxy]
end

function Utils.TryGetDB(query, arity)
    local db = Osi[query]
    if db and db.Get then
        return db:Get(table.unpack({}, 1, arity))
    end
end

function Utils.GetGUID(str)
    if str ~= nil and type(str) == 'string' then
        return string.sub(str, (string.find(str, "_[^_]*$") ~= nil and (string.find(str, "_[^_]*$") + 1) or 0), nil)
    end
    return ""
end

function Utils.UUIDEquals(item1, item2)
    if type(item1) == 'string' and type(item2) == 'string' then
        return (Utils.GetGUID(item1) == Utils.GetGUID(item2))
    end

    return false
end

function Utils.DeepClean(old)
    if (type(old) == "table" or type(old) == "userdata") and getmetatable(old) ~= "EntityProxy" then
        for k, v in pairs(old) do
            if (type(v) == "table" or type(v) == "userdata") and getmetatable(v) ~= "EntityProxy" then
                Utils.DeepClean(old[k])
            elseif getmetatable(v) ~= "EntityProxy" then
                pcall(protectedSet, old, k, nil)
            end
        end
    end
end

function Utils.DeepWrite(old, new)
    if (type(new) == "table" or type(new) == "userdata") and getmetatable(new) ~= "EntityProxy" then
        for k, v in pairs(new) do
            if (type(v) == "table" or type(v) == "userdata") and getmetatable(v) ~= "EntityProxy" then
                if (old == nil) then
                    old = {}
                end

                Utils.DeepWrite(old[k], v)
            elseif getmetatable(v) ~= "EntityProxy" then
                pcall(protectedSet, old, k, v)
            end
        end
    end
end

function Utils.CloneEntityEntry(old, new, entry)
    Utils.DeepClean(old[entry])
    Utils.DeepWrite(old[entry], new[entry])

    local ExcludedReps = Utils.Set(Constants.ExcludedReplications)

    if (not ExcludedReps[entry]) then
        old:Replicate(entry)
    end
end

-- We might not need this but I'm scared to remove it for edge-cases
function Utils.RepairNestedEntity(entity)
    local success, result = pcall(Utils.TryGetProxy, entity, "Item")

    if (success) then
        return result
    else
        return entity
    end
end

-- Readability purposes
-- Yeah yeah, we can make it one if statement but I want to know what's happening
function Utils.AllowGlamour(replacedEntity, glamourEntity, IsBypassed)
    -- We're bypassing glamour check for whatever reason
    if IsBypassed then
        return true
    end

    -- Entities exists
    if (replacedEntity == nil or glamourEntity == nil) then
        return false
        -- Original entity isn't summoned
    elseif (replacedEntity["IsSummon"] ~= nil) then
        return false
        -- Entities are not equipable
    else
        -- Confirm that Equipable is a proxy that exists in entity
        local replacedEntityEquipableSuccess, replacedEntityEquipable = pcall(Utils.TryGetProxy, replacedEntity, "Equipable")
        local glamourEntityEquipableSuccess, glamourEntityEquipable = pcall(Utils.TryGetProxy, glamourEntity, "Equipable")

        if (replacedEntityEquipableSuccess and glamourEntityEquipableSuccess) then
            if (replacedEntityEquipable == nil or replacedEntityEquipable == nil) then
                return false
                -- Entity slots are not the same or part of vanity sets
            elseif not (replacedEntityEquipable.Slot == glamourEntityEquipable.Slot
                    or (replacedEntityEquipable.Slot == "Breast" and glamourEntityEquipable.Slot == "VanityBody")
                    or (replacedEntityEquipable.Slot == "VanityBody" and glamourEntityEquipable.Slot == "Breast")
                    or (replacedEntityEquipable.Slot == "Boots" and glamourEntityEquipable.Slot == "VanityBoots")
                    or (replacedEntityEquipable.Slot == "VanityBoots" and glamourEntityEquipable.Slot == "Boots")) then
                return false
            end
        end
    end
    return true
end

function Utils.TemplateIsControlItem(template)
    for _, controlItem in pairs(Constants.ControlItems) do
        if (Utils.UUIDEquals(template, controlItem)) then
            return true
        end
    end
end

function Utils.IsWielding(entity, character)
    local success, result = pcall(Utils.TryGetProxy, entity, "Wielding")

    if (success) then
        return result ~= nil and result.Owner ~= nil and result.Owner.Uuid ~= nil
            and Utils.UUIDEquals(character, result.Owner.Uuid.EntityUuid)
    end

    return false
end

function Utils.GiveControlItems()
    local HostCharacter = Osi.GetHostCharacter()

    if Utils.Size(PersistentVars["ControlItems"]) == 0 then
        for _, controlItemTemplate in pairs(Constants.ControlItems) do
            Osi.TemplateAddTo(controlItemTemplate, HostCharacter, 1, 1)
        end
    else
        local ExistingControls = {}

        -- Check for existing control items
        for i, uuid in ipairs(PersistentVars["ControlItems"]) do
            local ControlItem = Osi.GetTemplate(uuid)
            if ControlItem ~= nil and type(ControlItem) == 'string' and Osi.Exists(uuid) ~= 0 then
                table.insert(ExistingControls, Utils.GetGUID(ControlItem))
            else
                table.remove(PersistentVars["ControlItems"], i)
            end
        end

        ExistingControls = Utils.Set(ExistingControls)

        -- Add missing control items
        for _, controlItemTemplate in pairs(Constants.ControlItems) do
            if not ExistingControls[controlItemTemplate] then
                Osi.TemplateAddTo(controlItemTemplate, HostCharacter, 1, 1)
            end
        end
    end
end

function Utils.Info(message)
    Ext.Utils.Print(TmE.modPrefix .. ' [Info] ' .. message)
end

function Utils.Warn(message)
    Ext.Utils.Print(TmE.modPrefix .. ' [Warning] ' .. message)
end

function Utils.Debug(message)
    Ext.Utils.Print(TmE.modPrefix .. ' [Debug] ' .. message)
end

function Utils.Error(message)
    Ext.Utils.Print(TmE.modPrefix .. ' [Error] ' .. message)
end
