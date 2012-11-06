local _, Viewda = ...

hooksecurefunc("EncounterJournal_LootCallback", function(itemID)
	local scrollFrame = EncounterJournal.encounter.info.lootScroll;

	for i,item in pairs(scrollFrame.buttons) do
		if item.itemID == itemID then
			print("item was updated", itemID)
			--[[local name, icon, slot, armorType, itemID, _, encounterID = EJ_GetLootInfoByIndex(item.index);
			item.name:SetText(name);
			item.icon:SetTexture(icon);
			item.slot:SetText(slot);
			item.boss:SetFormattedText(BOSS_INFO_STRING, EJ_GetEncounterInfo(encounterID));
			item.armorType:SetText(armorType); --]]
		end
	end
end)

local LPT = LibStub("LibPeriodicTable-3.1")
local reverseBoss = Viewda.Babble.boss:GetReverseLookupTable()
local reverseInstance = Viewda.Babble.subzone:GetReverseLookupTable()
local LPT_table, instance, boss, chance, setName

hooksecurefunc("EncounterJournal_LootUpdate", function()
	local scrollFrame = EncounterJournal.encounter.info.lootScroll;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local items = scrollFrame.buttons;
	local item, index;
	local numLoot = EJ_GetNumLoot()

	for i = 1,#items do
		item = items[i];
		index = offset + i
		boss, chance = nil, nil

		if index <= numLoot then
			if not EncounterJournal.encounterID then return end

			local bossName, _, _, sectionID = EJ_GetEncounterInfo(EncounterJournal.encounterID)
			local boss = reverseBoss[bossName]

			if sectionID then
				local sectionName, _, sectionType = EJ_GetSectionInfo(sectionID)
				if sectionType == 0 and string.find(sectionName, DUNGEON_DIFFICULTY) and string.find(sectionName, ITEM_HEROIC) then
					heroicOnly = true
				end
			end

			instance = reverseInstance[EJ_GetInstanceInfo(EncounterJournal.instanceID)]
			LPT_table = "InstanceLoot"
			if heroicOnly or EJ_GetDifficulty()%2 == 0 then LPT_table = LPT_table .. "Heroic"
			elseif EJ_GetDifficulty() == 5 then LPT_table = LPT_table .. "LFR"
			end

			if LPT_table and instance and boss then
				setName = LPT_table .."."..instance.."."..boss
				if not LPT.sets[setName] then
					setName = LPT_table .. "Heroic."..instance.."."..boss
				end

				local itemID = select(5, EJ_GetLootInfoByIndex(index))
				for item, value, set in LPT:IterateSet(setName) do
					if item == itemID then
						chance = (value * 0.1) .. '%'
						break
					end
				end
			end
		end

		if chance then
			if not item.chance then
				item.chance = item:CreateFontString(nil, "ARTWORK", "GameTooltipTextSmall")
				item.chance:SetAllPoints(item.icon)
				item.chance:SetShadowOffset(1, -1)
				item.chance:SetJustifyH("CENTER")
				item.chance:SetJustifyV("BOTTOM")
			end
			item.chance:SetText(chance)
		elseif item.chance then
			item.chance:SetText('')
		end
	end
end)
