ITEM.name = "LSD"
ITEM.description = "Some LSD, product quality is questionable these days."
ITEM.model = Model("models/jellik/lsd.mdl")
ITEM.category = "Drugs"
ITEM.width = 1
ITEM.height = 1

ITEM.functions.Eat = {
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