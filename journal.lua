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

local function UpdateLootChances()
	local scrollFrame = EncounterJournal.encounter.info.lootScroll
	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	local itemButtons = scrollFrame.buttons

	local index, itemID, slot, armorType, encounterID
	local subSet, setName, chance, lootButton, bossName

	local numLoot = EJ_GetNumLoot()
	local instanceName = EJ_GetInstanceInfo()
	local difficulty = EJ_GetDifficulty()

	--[[
		DIFFICULTY_DUNGEON_NORMAL = 1
		DIFFICULTY_DUNGEON_HEROIC = 2
		DIFFICULTY_RAID10_NORMAL = 3
		DIFFICULTY_RAID25_NORMAL = 4
		DIFFICULTY_RAID10_HEROIC = 5
		DIFFICULTY_RAID25_HEROIC = 6
		DIFFICULTY_RAID_LFR = 7
		DIFFICULTY_DUNGEON_CHALLENGE = 8
		DIFFICULTY_RAID40 = 9
	--]]
	if not EJ_IsValidInstanceDifficulty(difficulty) then
		if EJ_InstanceIsRaid() and difficulty < 3 then
			difficulty = difficulty + 2
		else
			difficulty = 1
			while difficulty < 10 and not EJ_IsValidInstanceDifficulty(difficulty) do
				difficulty = difficulty + 1
			end
			-- there is no valid difficulty? what the ...?
			if difficulty == 10 then return end
		end
	end

	local LPT_table = "InstanceLoot"
	if difficulty == DIFFICULTY_RAID_LFR then
		LPT_table = "InstanceLootLFR"
	elseif difficulty == DIFFICULTY_DUNGEON_HEROIC or difficulty > 4 then
		LPT_table = "InstanceLootHeroic"
	end

	for i = 1, #itemButtons do
		index = offset + i
		-- name, icon, slot, armorType, itemID, link, encounter
		_, _, slot, armorType, itemID, _, encounterID = EJ_GetLootInfoByIndex(index)

		if index <= numLoot then
			bossName = EJ_GetEncounterInfo(encounterID)
			bossName = reverseBoss[bossName]

			subSet = (reverseInstance[instanceName] and "."..reverseInstance[instanceName] or "")
			subSet = subSet .. (bossName and "."..bossName or "")
			setName = LPT_table .. subSet

			if subSet and subSet ~= "" and not LPT.sets[setName] then
				if LPT.sets["InstanceLootHeroic" .. subSet] then
					setName = "InstanceLootHeroic" .. subSet
				elseif LPT.sets["InstanceLoot" .. subSet] then
					setName = "InstanceLoot" .. subSet
				elseif LPT.sets["InstanceLootLFR" .. subSet] then
					setName = "InstanceLootLFR" .. subSet
				else
					setName = nil
				end
			end

			if not setName then
				chance = nil
			else
				for item, value, set in LPT:IterateSet(setName) do
					if item == itemID then
						if value and tonumber(value) > 0 then
							chance = string.format("%.2f%%", value * 0.1)
						else
							chance = nil
						end
						break
					end
				end
			end
		end

		lootButton = itemButtons[i]
		lootButton.armorType:SetText(chance or '')
		if armorType and armorType ~= '' then
			lootButton.slot:SetText((slot ~= '' and slot..', ' or '') .. (armorType or ''))
		end
	end
end
hooksecurefunc("EncounterJournal_LootUpdate", UpdateLootChances)
hooksecurefunc(EncounterJournal.encounter.info.lootScroll, 'update', UpdateLootChances)
