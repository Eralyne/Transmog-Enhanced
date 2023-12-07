---@diagnostic disable: undefined-global

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                        Table Helpers                                        --
--                                                                                             --
-------------------------------------------------------------------------------------------------

function Utils.Set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

function Utils.Size(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function Utils.Equals(o1, o2, ignore_mt)
    if o1 == o2 then return true end
    local o1Type = type(o1)
    local o2Type = type(o2)
    if o1Type ~= o2Type then return false end
    if o1Type ~= 'table' then return false end

    if not ignore_mt then
        local mt1 = getmetatable(o1)
        if mt1 and mt1.__eq then
            --compare using built in method
            return o1 == o2
        end
    end

    local keySet = {}

    for key1, value1 in pairs(o1) do
        local value2 = o2[key1]
        if value2 == nil or Utils.Equals(value1, value2, ignore_mt) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(o2) do
        if not keySet[key2] then return false end
    end
    return true
end

--- @param t table
--- @param toRemove table
function Utils.Remove(t, toRemove)
    local i, j, n = 1, 1, #t
    while i <= n do
        if (Utils.Equals(t[i], toRemove)) then
            local k = i
            repeat
                i = i + 1
            until i > n or not fnKeep(t, i, j + i - k)
            table.move(t, k, i - 1, j)
            j = j + i - k
        end
        i = i + 1
    end
    table.move(t, n + 1, n + n - j + 1, j)
    return t
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                      Protected Helpers                                      --
--                                                                                             --
-------------------------------------------------------------------------------------------------

function Utils.TryGetProxy(entity, proxy)
    return entity[proxy]
end

function Utils.TryGetDB(query, arity)
    local db = Osi[query]
    if db and db.Get then
        return db:Get(table.unpack({}, 1, arity))
    end
end

local function protectedSet(old, key, value)
    old[key] = value
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                         SE Helpers                                          --
--                                                                                             --
-------------------------------------------------------------------------------------------------

-- Credit: LazyIcarus for the implementation idea
function DelayedCall(ms, func)
    local Time = 0
    local handler
    handler = Ext.Events.Tick:Subscribe(function(e)
        Time = Time + e.Time.DeltaTime

        if (Time >= ms) then
            Ext.Events.Tick:Unsubscribe(handler)
            func()
        end
    end)
end

-- Credit: Yoinked from Morbyte
function TryToReserializeObject(original, clone)
    local serializer = function()
        local serialized = Ext.Types.Serialize(clone)
        Ext.Types.Unserialize(original, serialized)
    end

    local ok, err = xpcall(serializer, debug.traceback)
    if not ok then
        return err
    elseif not err then
        return "Mismatch"
    else
        return nil
    end
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                         UUID Helpers                                        --
--                                                                                             --
-------------------------------------------------------------------------------------------------

function Utils.IsGUID(string)
    local x = "%x"
    local t = { x:rep(8), x:rep(4), x:rep(4), x:rep(4), x:rep(12) }
    local pattern = table.concat(t, '%-')

    return string:match(pattern)
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

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                     Entity Replication                                      --
--                                                                                             --
-------------------------------------------------------------------------------------------------

function Utils.DeepClean(old)
    local permittedCopyObjects = Utils.Set(Constants.PermittedCopyObjects)
    if permittedCopyObjects[getmetatable(old)] then
        for k, v in pairs(old) do
            if (k ~= "Template" and k ~= "OriginalTemplate") then
                if permittedCopyObjects[getmetatable(v)] then
                    Utils.DeepClean(old[k])
                elseif getmetatable(v) ~= "EntityProxy" then
                    pcall(protectedSet, old, k, 0)
                    pcall(protectedSet, old, k, "")
                    pcall(protectedSet, old, k, nil)
                end
            end
        end
    end
end

function Utils.DeepWrite(old, new)
    local permittedCopyObjects = Utils.Set(Constants.PermittedCopyObjects)
    if permittedCopyObjects[getmetatable(new)] then
        for k, v in pairs(new) do
            if (k ~= "Template" and k ~= "OriginalTemplate") then
                if permittedCopyObjects[getmetatable(v)] then
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
end

function Utils.CloneProxy(old, new, hasTemplate)
    if (Ext.Utils.Version() > 9) then
        if (hasTemplate) then
            for k, v in pairs(new) do
                if (k ~= "Template" and k ~= "OriginalTemplate") then
                    TryToReserializeObject(old[k], v)
                end
            end
        else
            TryToReserializeObject(old, new)
        end
    else
        Utils.DeepClean(old)
        Utils.DeepWrite(old, new)
    end
end

function Utils.CloneWriteOnly(old, new)
    if (Ext.Utils.Version() > 9) then
        TryToReserializeObject(old, new)
    else
        DeepWrite(old, new)
    end
end

function Utils.CloneEntityEntry(old, new, entry)
    local hasTemplate = false

    if (entry == "ServerItem") then
        hasTemplate = true
    end

    Utils.CloneProxy(old[entry], new[entry], hasTemplate)

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

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                       Glamour Work                                          --
--                                                                                             --
-------------------------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                        Logging                                              --
--                                                                                             --
-------------------------------------------------------------------------------------------------

function Utils.Info(message)
    Ext.Utils.Print(TME.modPrefix .. ' [Info] ' .. message)
end

function Utils.Warn(message)
    Ext.Utils.Print(TME.modPrefix .. ' [Warning] ' .. message)
end

function Utils.Debug(message)
    Ext.Utils.Print(TME.modPrefix .. ' [Debug] ' .. message)
end

function Utils.Error(message)
    Ext.Utils.Print(TME.modPrefix .. ' [Error] ' .. message)
end
