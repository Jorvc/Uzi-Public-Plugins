ITEM.name = "Cocaine"
ITEM.description = "A manufactured bag of cocaine, an old ration pack has been used to bag it."
ITEM.model = Model("models/foodnhouseholdaaaaa/combirationa.mdl")
ITEM.category = "Drugs"
ITEM.width = 1
ITEM.height = 1

ITEM.functions.Sniff = {
	sound = "npc/barnacle/barnacle_gulp1.wav",
	OnRun = function(itemTable)
		local client = itemTable.player

		client:GetCharacter():AddBoost("debuff1", "agi", -2)
		client:GetCharacter():AddBoost("debuff2", "stm", -2)
		client:GetCharacter():AddBoost("buff1", "fue", 3)

		hook.Run("SetupDrugTimer", client, client:GetCharacter(), itemTable.uniqueID, 1800)
	end
}

ITEM.screenspaceEffects = function()
	DrawMotionBlur(0.25, 1, 0)
end