ModUtil.Mod.Register( "PolycosmosHelperManager" )


local HelpersDataArray=
{
    "MaxHealthHelper",
}


local valueLoaded = false

local MaxHealthRequests = 0
local BoonBoostRequests = 0


-------------------- Auxiliary function for checking if a item is a filler item
function PolycosmosHelperManager.IsHelperItem(string)
    return PolycosmosUtils.HasValue(HelpersDataArray, string)
end

--------------------

function PolycosmosHelperManager.GiveHelperItem(item)
    if (item == "MaxHealthHelper") then
        MaxHealthRequests = MaxHealthRequests + 1
    elseif (item == "BoonBoostHelper") then
        BoonBoostRequests = BoonBoostRequests + 1
    end
end

--------------------

function PolycosmosHelperManager.FlushAndProcessFillerItems()
    if (GameState.FillerItemLodger == nil) then
        GameState.FillerItemLodger = {}
        GameState.FillerItemLodger["MaxHealthHelper"] = 0
        GameState.FillerItemLodger["BoonBoostHelper"] = 0
    end

    while (MaxHealthRequests > GameState.FillerItemLodger["MaxHealthHelper"]) do
        CurrentRun.Hero.Health = CurrentRun.Hero.Health + 25
        GameState.FillerItemLodger["MaxHealthHelper"] = GameState.FillerItemLodger["MaxHealthHelper"] + 1
        PolycosmosMessages.PrintToPlayer("Received a Max Health boost!")
    end

    while (BoonBoostRequests > GameState.FillerItemLodger["BoonBoostHelper"]) do
        GameState.FillerItemLodger["BoonBoostHelper"] = GameState.FillerItemLodger["BoonBoostHelper"] + 1
        PolycosmosMessages.PrintToPlayer("Received a Boon Rarity boost!")
    end

    MaxHealthRequests = 0
    BoonBoostRequests = 0

    SaveCheckpoint({ SaveName = "_Temp", DevSaveName = CreateDevSaveName( CurrentRun, { PostReward = true } ) })
    ValidateCheckpoint({ Valid = true })

    Save()
end

--------------------

function GetRarityChancesOverride( args )
	local name = args.Name
	local ignoreTempRarityBonus = args.IgnoreTempRarityBonus
	local referencedTable = "BoonData"
	if name == "StackUpgrade" then
		referencedTable = "StackData"
	elseif name == "WeaponUpgrade" then
		referencedTable = "WeaponData"
	elseif name == "HermesUpgrade" then
		referencedTable = "HermesData"
	end

	local legendaryRoll = CurrentRun.Hero[referencedTable].LegendaryChance or 0
	local heroicRoll = CurrentRun.Hero[referencedTable].HeroicChance or 0
	local epicRoll = CurrentRun.Hero[referencedTable].EpicChance or 0
	local rareRoll = CurrentRun.Hero[referencedTable].RareChance or 0

	if CurrentRun.CurrentRoom.BoonRaritiesOverride then
		legendaryRoll = CurrentRun.CurrentRoom.BoonRaritiesOverride.LegendaryChance or legendaryRoll
		heroicRoll = CurrentRun.CurrentRoom.BoonRaritiesOverride.HeroicChance or heroicRoll
		epicRoll = CurrentRun.CurrentRoom.BoonRaritiesOverride.EpicChance or epicRoll
		rareRoll =  CurrentRun.CurrentRoom.BoonRaritiesOverride.RareChance or rareRoll
	elseif args.BoonRaritiesOverride then
		legendaryRoll = args.BoonRaritiesOverride.LegendaryChance or legendaryRoll
		heroicRoll = args.BoonRaritiesOverride.HeroicChance or heroicRoll
		epicRoll = args.BoonRaritiesOverride.EpicChance or epicRoll
		rareRoll =  args.BoonRaritiesOverride.RareChance or rareRoll
	end

	local metaupgradeRareBoost = GetNumMetaUpgrades( "RareBoonDropMetaUpgrade" ) * ( MetaUpgradeData.RareBoonDropMetaUpgrade.ChangeValue - 1 )
	local metaupgradeEpicBoost = GetNumMetaUpgrades( "EpicBoonDropMetaUpgrade" ) * ( MetaUpgradeData.EpicBoonDropMetaUpgrade.ChangeValue - 1 ) + GetNumMetaUpgrades( "EpicHeroicBoonMetaUpgrade" ) * ( MetaUpgradeData.EpicBoonDropMetaUpgrade.ChangeValue - 1 )
	local metaupgradeLegendaryBoost = GetNumMetaUpgrades( "DuoRarityBoonDropMetaUpgrade" ) * ( MetaUpgradeData.EpicBoonDropMetaUpgrade.ChangeValue - 1 )
	local metaupgradeHeroicBoost = GetNumMetaUpgrades( "EpicHeroicBoonMetaUpgrade" ) * ( MetaUpgradeData.EpicBoonDropMetaUpgrade.ChangeValue - 1 )
	legendaryRoll = legendaryRoll + metaupgradeLegendaryBoost + (GameState.FillerItemLodger["BoonBoostHelper"]*0.01)
	heroicRoll = heroicRoll + metaupgradeHeroicBoost + (GameState.FillerItemLodger["BoonBoostHelper"]*0.01)
	rareRoll = rareRoll + metaupgradeRareBoost + (GameState.FillerItemLodger["BoonBoostHelper"]*0.01)
	epicRoll = epicRoll + metaupgradeEpicBoost + (GameState.FillerItemLodger["BoonBoostHelper"]*0.01)

	local rarityTraits = GetHeroTraitValues("RarityBonus", { UnlimitedOnly = ignoreTempRarityBonus })
	for i, rarityTraitData in pairs(rarityTraits) do
		if rarityTraitData.RequiredGod == nil or rarityTraitData.RequiredGod == name then
			if rarityTraitData.RareBonus then
				rareRoll = rareRoll + rarityTraitData.RareBonus
			end
			if rarityTraitData.EpicBonus then
				epicRoll = epicRoll + rarityTraitData.EpicBonus
			end
			if rarityTraitData.HeroicBonus then
				heroicRoll = heroicRoll + rarityTraitData.HeroicBonus
			end
			if rarityTraitData.LegendaryBonus then
				legendaryRoll = legendaryRoll + rarityTraitData.LegendaryBonus
			end
		end
	end
	return
	{
		Rare = rareRoll,
		Epic = epicRoll,
		Heroic = heroicRoll,
		Legendary = legendaryRoll,
	}
end


ModUtil.Path.Wrap("GetRarityChancesOverride", function(baseFunc, args)
    return GetRarityChancesOverride( args )
end, PolycosmosHelperManager)