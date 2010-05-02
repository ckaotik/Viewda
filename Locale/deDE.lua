_, Viewda = ...

if GetLocale() == "deDE" then
	Viewda.locale.equipLocation = {
		["INVTYPE_HEAD"] = "Kopf", 
		["INVTYPE_NECK"] = "Hals",
		["INVTYPE_SHOULDER"] = "Schulter",
		["INVTYPE_CHEST"] = "Brust",
		["INVTYPE_ROBE"] = "Brust",
		["INVTYPE_WAIST"] = "Gürtel",
		["INVTYPE_LEGS"] = "Hosen", 
		["INVTYPE_FEET"] = "Stiefel",
		["INVTYPE_WRIST"] = "Arme",
		["INVTYPE_HAND"] = "Hände",
		["INVTYPE_FINGER"] = "Ring",
		["INVTYPE_TRINKET"] = "Schmuck",
		["INVTYPE_CLOAK"] = "Umhang",
		
		["INVTYPE_BODY"] = "Hemd",
		["INVTYPE_TABARD"] = "Wappenrock",
		["INVTYPE_BAG"] = "Tasche",
		
		["INVTYPE_WEAPON"] = "Einhand",
		["INVTYPE_2HWEAPON"] = "Zweihand",
		["INVTYPE_WEAPONMAINHAND"] = "Waffenhand",
		["INVTYPE_WEAPONOFFHAND"] = "Schildhand", 
		["INVTYPE_HOLDABLE"] = "Nebenhand",	-- held in off-hand
		["INVTYPE_SHIELD"] = "Schildhand",
		
		["INVTYPE_RANGEDRIGHT"] = "Fernkampf",	-- wands, guns, crossbows
		["INVTYPE_THROWN"] = "Wurfwaffen",
		["INVTYPE_RANGED"] = "Bogen",
		["INVTYPE_AMMO"] = "Munition",
		["INVTYPE_RELIC"] = "Relikt",
	}
	Viewda.locale.ShortenItemSlot = function(text)
		if string.find(text, "^Einhand") or string.find(text, "^Zweihand") then
			text = string.gsub(text, "^Einhand", "")
			text = string.gsub(text, "^Zweihand", "")
			text = string.gsub(text, "^([\128-\196].)", string.upper)	-- if this starts with a UTF-8 special character
			text = string.gsub(text, "^[^\128-\196]", string.upper)
		end
		return text
	end
	
	Viewda.locale.leftClickToggle = "Klick: Zeigen/Verstecken"
	Viewda.locale.rightClickConfig = "Rechts-Klick: Optionen"
	
	Viewda.locale.unknown = "Unbekannt"
	Viewda.locale.category = "Kategorie"
	Viewda.locale.favorites = "Favoriten"
	
	Viewda.locale.tooltipMenuButton = "Klicke um eine Ebene zurück zu gehen.\nRechts-Klick zum Index."
	Viewda.locale.selectionButtonText = "Klicke um eine Tabelle auszuwählen!"
	Viewda.locale.clickForCloseUp = "Klicke für Details"
	
	Viewda.locale.tooltipQueryServer = "Dein Client kennt dieses item noch nicht. Rechts-Klick um vom Server Informationen anzufragen"
	Viewda.locale.tooltipUpdateIcon = "Rechtsklicke um den Eintrag zu aktualisieren."
	Viewda.locale.chatQueryServer = "Anfrage an den Server wurde gestellt. Rechts-Klick auf den Eintrag um ihn zu aktualisieren."
	
	Viewda.locale.setNotFound = "Dieses Set konnte nicht gefunden werden!\n\nLibPeriodicTable erstellt teilweise Kreuzverweise, die von Viewda noch nicht unterstützt werden.\n\nDu kannst die Einträge in einer anderen Kategorie finden, z.B. \"Tradeskill.Mat.BySource.Gather\" lässt sich bei \"Tradeskill.Gather\" finden."
	Viewda.locale.noFavorites = "Du hast noch keine Favoriten!\n\nFinde Gegenstände, Zauber oder Kategorien, die dir gefallen und klicke auf das Stern-Icon um sie zu deinen Favoriten hinzuzufügen.\n\nSo markierte Einträge werden dann hier angezeigt!"
	
	Viewda.locale.optionsSubTitle = "Es sind nicht viele Optionen, aber es gibt sie. Pass' sie dir an, wie du magst."
	Viewda.locale.optionsColorByRole = "Icon-Rahmen: Instanz-Rolle"
	Viewda.locale.optionsColorByRoleTooltip = "Wenn ausgewählt, wird eine zusätzliche Textur über dem icon angezeigt, um zu verdeutlichen für welche Rolle das Item gedacht ist."
	Viewda.locale.optionsChatMessageQueried = "Chatnachricht: Itemanfrage"
	Viewda.locale.optionsChatMessageQueriedTooltip = "Wenn ausgewählt, wird im Chat eine Nachricht ausgegeben wenn eine Itemanfrage an den Server geht."
	Viewda.locale.optionsMouseOverQuery = "Intemanfrage beim MouseOver"
	Viewda.locale.optionsMouseOverQueryTooltip = "Wenn aktiviert, wird ein unbekanntes Item schon beim Überfahren des Icons vom Server angefragt.\nMit Vorsicht verwenden."
end