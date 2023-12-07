---@diagnostic disable: undefined-global

-- Local Functions --

local function protectedSet(old, key, value)
    old[key] = value
end

function Utils.TryGetProxy(entity, proxy)
    return entity[proxy]
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

function Utils.TryGetDB(query, arity)
    local db = Osi[query]
    if db and db.Get then
        return db:Get(table.unpack({}, 1, arity))
    end
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
function Utils.AllowGlamour(replacedEntity, glamourEntity)
    -- Entities exists
    if (replacedEntity == nil or glamourEntity == nil) then
        return false
        -- Original entity isn't summoned
    elseif (replacedEntity["IsSummon"] ~= nil) then
        return false
        -- Entities are not equipable
    elseif (replacedEntity.Equipable == nil or glamourEntity.Equipable == nil) then
        return false
        -- Entity slots are not the same or part of vanity sets
    elseif not (replacedEntity.Equipable.Slot == glamourEntity.Equipable.Slot
            or (replacedEntity.Equipable.Slot == "Breast" and glamourEntity.Equipable.Slot == "VanityBody")
            or (replacedEntity.Equipable.Slot == "VanityBody" and glamourEntity.Equipable.Slot == "Breast")
            or (replacedEntity.Equipable.Slot == "Boots" and glamourEntity.Equipable.Slot == "VanityBoots")
            or (replacedEntity.Equipable.Slot == "VanityBoots" and glamourEntity.Equipable.Slot == "Boots")) then
        return false
    end

    return true
end

function Utils.IsWielding(entity, character)
    local success, result = pcall(Utils.TryGetProxy, entity, "Wielding")

    if (success) then
        return result ~= nil and result.Owner ~= nil and result.Owner.Uuid ~= nil
            and (result.Owner.Uuid.EntityUuid == character
                or (type(character) == "string" and type(result.Owner.Uuid.EntityUuid) == "string" and string.len(character) > string.len(result.Owner.Uuid.EntityUuid)
                    and string.sub(character, -36) == result.Owner.Uuid.EntityUuid))
    end

    return false
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
