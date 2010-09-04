_, Viewda = ...

Viewda.locale = {
	equipLocation = {
		["INVTYPE_HEAD"] = "Head", 
		["INVTYPE_NECK"] = "Neck",
		["INVTYPE_SHOULDER"] = "Shoulder",
		["INVTYPE_CHEST"] = "Chest",
		["INVTYPE_ROBE"] = "Chest",
		["INVTYPE_WAIST"] = "Waist",
		["INVTYPE_LEGS"] = "Legs", 
		["INVTYPE_FEET"] = "Feet",
		["INVTYPE_WRIST"] = "Wrist",
		["INVTYPE_HAND"] = "Hands",
		["INVTYPE_FINGER"] = "Ring",
		["INVTYPE_TRINKET"] = "Trinket",
		["INVTYPE_CLOAK"] = "Cloak",
		
		["INVTYPE_BODY"] = "Body",
		["INVTYPE_TABARD"] = "Tabard",
		["INVTYPE_BAG"] = "Bag",
		
		["INVTYPE_WEAPON"] = "One-Handed",
		["INVTYPE_2HWEAPON"] = "Two-Handed",
		["INVTYPE_WEAPONMAINHAND"] = "Main-Hand",
		["INVTYPE_WEAPONOFFHAND"] = "Off-Hand", 
		["INVTYPE_HOLDABLE"] = "Holdable",	-- held in off-hand
		["INVTYPE_SHIELD"] = "Shield",
		
		["INVTYPE_RANGEDRIGHT"] = "Ranged",	-- wands, guns, crossbows
		["INVTYPE_THROWN"] = "Thrown",
		["INVTYPE_RANGED"] = "Ranged",
		["INVTYPE_AMMO"] = "Ammo",
		["INVTYPE_RELIC"] = "Relic",
	},
	ShortenItemSlot = function(text)
		if not text then return end
		--[[if string.find(text, "^Einhand") or string.find(text, "^Zweihand") then
			text = string.gsub(text, "^Einhand", "")
			text = string.gsub(text, "^Zweihand", "")
			text = string.gsub(text, "^%l", string.upper)
		end]]
		return text
	end,
	
	leftClickToggle = "Click: Show/Hide", 
	rightClickConfig = "Right-Click: Config",
	
	unknown = "Unknown",
	search = "Search ...",
	category = "Category",
	favorites = "Favorites",
	
	tooltipMenuButton = "Click to go back one level.\nRight-Click to go to the index.",
	selectionButtonText = "Click to select a table!",
	clickForCloseUp = "Click for details",
	
	tooltipQueryServer = "This item is not yet known to your client. Right-Click to ask the server for information.",
	tooltipUpdateIcon = "Right-click again to update the display.",
	chatQueryServer = "Queried item to the server. Right-click the icon to refresh the display.",
	
	setNotFound = "This set was not found!\n\nLibPeriodicTable sometimes creates cross-references which are not yet supported by Viewda.\n\nThe items are not gone! Find them in another category, e.g. \"Tradeskill.Mat.BySource.Gather\" can be found in \"Tradeskill.Gather\".",
	noFavorites = "You have no favorites to display!\n\nFind items you would like to watch and click on the star icon to mark them as a favorite.\n\nMarked items/spells/categories will show up here!",
	
	optionsSubTitle = "Suit yourself and adjust these settings to your liking.",
	optionsColorByRole = "Color-Overlay: Dungeon Role",
	optionsColorByRoleTooltip = "When checked creates an overlay texture for equippable items depending on the character role they are meant for.",
	optionsChatMessageQueried = "Chat Message: Item Queried",
	optionsChatMessageQueriedTooltip = "When checked a message will be printed when requesting items from the server.",
	optionsMouseOverQuery = "Query items on MouseOver",
	optionsMouseOverQueryTooltip = "This will trigger a server request for the hovered item.\nUse with caution.",
}