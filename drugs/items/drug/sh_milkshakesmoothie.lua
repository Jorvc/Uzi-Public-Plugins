ITEM.name = "Xenian Mushroom Smoothie"
ITEM.description = "A bottle containing a strange white juice ... A very common homemade drink among Vortigaunts, its effects on humans are unknown."
ITEM.model = Model("models/jellik/lean.mdl")
ITEM.category = "Drugs"
ITEM.width = 1
ITEM.height = 1

ITEM.functions.Drink = {
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