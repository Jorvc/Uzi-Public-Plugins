local PLUGIN = PLUGIN

PLUGIN.name = "Terminal"
PLUGIN.author = "Madeon & POTATO"
PLUGIN.description = "Adds a terminal which can manage people's LP & data"

function PLUGIN:CanProperty(client, property, entity)
	if property == "persist" 
	and entity:GetClass() == "terminal" then
		return false
	end
end