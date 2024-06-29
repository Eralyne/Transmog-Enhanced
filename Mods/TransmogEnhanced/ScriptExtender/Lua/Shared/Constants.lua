Constants.ModUUID = "82c1f53b-5ed3-4e2e-95f5-f84ca6ff0c81"

Constants.Replications = {
    "AttributeFlags",
    "Armor",
    -- "BoostsContainer",
    "CanBeDisarmed",
    "CombatParticipant",
    "Data",
    "DisplayName",
    "Equipable",
    -- "IsGlobal",
    "ItemBoosts",
    -- "Net",
    "GameplayLight",
    "ObjectSize",
    "PassiveContainer",
    "ServerItem",
    -- "Physics",
    -- "Speaker",
    "StatusImmunities",
    "Tag",
    -- "Transform",
    "TurnBased",
    "Use",
    "Value",
    "Weapon",
    -- "IsSummon",
    -- "Wielding"
}

Constants.SaveLoadReplications = {
    "DisplayName",
    "ServerDisplayNameList",
	"Tag"
}

Constants.ExcludedReplications = {
    "ServerIconList",
    "ServerDisplayNameList",
    "ServerItem"
}

Constants.PermittedCopyObjects = {
    "bg3se::Array",
    "bg3se::Object",
}

Constants.PermittedUseObjects = {
    "bg3se::Array",
    "bg3se::Object",
    "bg3se::Map",
    "table"
}

Constants.BoostsEntityReplication = {
    "BoostInfo",
    "WeaponDamageBoost",
}

--need to exclude BoostInfo.BoostEntity
--need to exclude BoostInfo.Owner
--need to exclude BoostInfo.Cause.Entity
--idk what field_80
--Exclude ServerREplicationDependency
Constants.BoostsEntityExcludeClone = {
    "BoostEntity",
    "Owner",
}

Constants.BoostsExcludedStatuses = {
    "MAG_FIRE_ALWAYS_DIPPED_FIRE"
}

Constants.BoostsSlots = {
    "MeleeMainHand",
    "MeleeOffHand",
    "RangedMainHand",
    "RangedOffHand"
}

Constants.HideAppearanceRing = {
    "ServerIconList",
    "Icon",
    "GameObjectVisual",
}

Constants.DefaultUUIDs = {
    ["TMogNullTemplate"] = "00000000-0000-0000-0000-000000000000",
    ["TMogVanillaRingTemplate"] = "173aad0e-0db4-4f2f-8f24-49e6898b8f90",
    ["HideyHoleFallback"] = "0133f2ad-e121-4590-b5f0-a79413919805"
}

Constants.ControlItems = {
    ["TMogReplacerTemplate"] = 'e64e7287-d830-44a9-bbf9-0903a1cb48ec',
    ["TMogCleanerTemplate"] = '421dfd89-ae60-4f1e-bd7c-14463bfd50b5',
    ["TMogHiderTemplate"] = 'b3f22ee2-e1be-4b82-beb1-195d8bf41e01'
}
