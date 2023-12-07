---@diagnostic disable: undefined-global
local TransmogCharacter
local TransmogTemplate
local ReplacedItem
local CombineRequest
local isGlamoured
local UsedControlItem

-- Maybe find a better HideyHole?
local HideyHole

---@param character CHARACTER
---@param controlItem ITEM
---@param item2 ITEM
---@param glamourAppearance ITEM
---@diagnostic disable-next-line: duplicate-doc-param
---@param _ ITEM
---@diagnostic disable-next-line: duplicate-doc-param
---@param _ ITEM
---@param requestID integer
Ext.Osiris.RegisterListener("RequestCanCombine", 7, "before", function(character, controlItem, item2, glamourAppearance, _, _, requestID)
    -- Only do the work if the first combo item is the tmog item
    if (string.sub(Osi.GetTemplate(controlItem), -36) == Constants.ControlItems["TMogReplacerTemplate"]) or (string.sub(Osi.GetTemplate(controlItem), -36) == Constants.ControlItems["TMogCleanerTemplate"]) then
        UsedControlItem = controlItem

        CombineRequest = requestID

        TransmogCharacter = character

        ReplacedItem = item2
        TransmogTemplate = Osi.GetTemplate(glamourAppearance)

        ReplacedEntity = Utils.RepairNestedEntity(Ext.Entity.Get(item2))
        local TransmogEntity = Utils.RepairNestedEntity(Ext.Entity.Get(glamourAppearance))

        if (Utils.AllowGlamour(ReplacedEntity, TransmogEntity)) then
            if (PersistentVars["GlamouredItems"][item2] ~= nil) then
                -- TODO: Data replication happening here, we can set isGlamoured to a boolean
                -- However, right now I'm afraid to touch it too much lmao
                isGlamoured = item2
                ReplacedItem = item2
            end

            -- I wish we could get the uuid of the new item, but alas, we must listen to it and pray no one else is tmoging at the same time.
            Osi.TemplateAddTo(TransmogTemplate, HideyHole, 1, 0)
        elseif (ReplacedEntity ~= nil and not TransmogEntity) and (PersistentVars["GlamouredItems"][item2] ~= nil) then
            -- isGlamoured = item2
            CombineRequest = requestID

            Osi.ToInventory(PersistentVars["GlamouredItems"][item2], TransmogCharacter, 1, 1, 0)

            -- Unequip and re-equip if current character is wielding
            if (Utils.IsWielding(ReplacedEntity, TransmogCharacter)) then
                Osi.Unequip(TransmogCharacter, ReplacedItem)
                Osi.Equip(TransmogCharacter, PersistentVars["GlamouredItems"][item2])
            end

            PersistentVars["GlamouredItems"][item2] = nil
            Osi.RequestDelete(ReplacedItem)

            Osi.RequestProcessed(TransmogCharacter, CombineRequest, 1)

            Osi.Use(TransmogCharacter, controlItem, "")
        end
    end
end)

---@param template ROOT
---@param uuid GUIDSTRING
---@param character GUIDSTRING
---@param _ string
Ext.Osiris.RegisterListener("TemplateAddedTo", 4, "before", function(template, uuid, character, _)
    -- Handle TMOG
    if (template == TransmogTemplate and (character == HideyHole) or (type(character) == "string" and type(HideyHole) == "string" and string.len(character) > string.len(HideyHole) and string.sub(character, -36) == HideyHole)) then
        TransmogTemplate = nil

        local NewItem = Utils.RepairNestedEntity(Ext.Entity.Get(uuid))

        for _, entry in ipairs(Constants.Replications) do
            Utils.CloneEntityEntry(NewItem, ReplacedEntity, entry)
        end

        -- I don't know why but we have to unpack the boosts here cuz my DeepWrite SUCKS APPARENTLY GAH
        NewItem.Use.Boosts = { table.unpack(ReplacedEntity.Use.Boosts) }

        if (isGlamoured ~= nil) then
            PersistentVars["GlamouredItems"][uuid] = PersistentVars["GlamouredItems"][isGlamoured]
            PersistentVars["GlamouredItems"][isGlamoured] = nil


            Osi.RequestDelete(isGlamoured)
            isGlamoured = nil
        else
            PersistentVars["GlamouredItems"][uuid] = ReplacedItem
            Osi.ToInventory(ReplacedItem, HideyHole, 1, 0, 0)
        end

        ReplacedItem = nil

        -- Let's Replicate again for funzies
        for _, entry in ipairs(Constants.Replications) do
            local ExcludedReps = Utils.Set(Constants.ExcludedReplications)

            if (not ExcludedReps[entry]) then
                NewItem:Replicate(entry)
            end
        end

        -- We do it this way to show a notification of the new item :)
        Osi.ToInventory(uuid, TransmogCharacter, 1, 1, 1)

        -- Re-equip only if the tmogging character had it equipped
        if (Utils.IsWielding(ReplacedEntity, TransmogCharacter)) then
            Osi.Equip(TransmogCharacter, uuid)
        end

        -- Reset combine ui
        Osi.RequestProcessed(TransmogCharacter, CombineRequest, 1)
        Osi.Use(TransmogCharacter, UsedControlItem, "")

        CombineRequest = nil
        TransmogCharacter = nil
        UsedControlItem = nil
    elseif (string.sub(template, -36) == Constants.ControlItems["TMogReplacerTemplate"]) or (string.sub(template, -36) == Constants.ControlItems["TMogCleanerTemplate"]) then
        -- Handle Control Items
        PersistentVars["ControlItems"][uuid] = character
    end
end)


Ext.Osiris.RegisterListener("SavegameLoaded", 0, "after", function()
    local HostCharacter = Osi.GetHostCharacter()

    local success, _ = pcall(Utils.TryGetDB, "DB_CharacterCreation_FirstDummy", 1)
    if success then
        HideyHole = Osi["DB_CharacterCreation_FirstDummy"]:Get(nil)[1][1]
    else
        HideyHole = HostCharacter
    end


    -- Add control items
    if Utils.Size(PersistentVars["ControlItems"]) == 0 then
        for _, controlItemTemplate in pairs(Constants.ControlItems) do
            Osi.TemplateAddTo(controlItemTemplate, HostCharacter, 1, 1)
        end
    else
        local ExistingControls = {}

        -- Check for existing control items
        for k, _ in pairs(PersistentVars["ControlItems"]) do
            local ControlItem = Osi.GetTemplate(k)
            if ControlItem ~= nil and string.len(ControlItem) > 36 then
                table.insert(ExistingControls, string.sub(ControlItem, -36))
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

    -- Fix Names (replication of ServerDisplayNameList isn't done so we have to do this for now)
    for glamouredItem, originItem in pairs(PersistentVars["GlamouredItems"]) do
        local GlamouredEntity = Utils.RepairNestedEntity(Ext.Entity.Get(glamouredItem))
        local OriginEntity = Utils.RepairNestedEntity(Ext.Entity.Get(originItem))

        Utils.DeepWrite(GlamouredEntity["ServerDisplayNameList"], OriginEntity["ServerDisplayNameList"])
        Utils.DeepWrite(GlamouredEntity["DisplayName"], OriginEntity["DisplayName"])
        GlamouredEntity:Replicate("DisplayName")
    end
end)
