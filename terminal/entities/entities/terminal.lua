
AddCSLuaFile()

ENT.Base = "base_gmodentity"
ENT.Type = "anim"

ENT.PrintName= "Terminal"
ENT.Category="HL2 RP"

ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "TerminalName")
end

properties.Add("TerminalName", {
    MenuLabel = "Set Terminal's Name",
    Order = 999, 
    MenuIcon = "icon16/brick_edit.png",
    Filter = function(self, ent, ply)
        if (ent:GetClass() != "terminal") then return false end -- return class, if not terminal end
        if (!ply:IsAdmin()) then return false end --return player group, if it's not admin then end
        return true 
    end,
    Action = function(self, ent) --what to do when clicked on
        Derma_StringRequest("Set Terminal Name", "Terminal Name:", ent:GetTerminalName(), function(text) --Main Title: Set Terminal Name, Subtitle: Terminal Name:, Default: GetTerminalName()
            self:MsgStart() -- literally just some garbage that has one purpose, which is for properties.Add
            net.WriteEntity(ent) --ent for the entity it's referring to, self for table
            net.WriteString(text) -- write text written from the Derma_StringRequest if given OK'd
            self:MsgEnd() -- another piece of garbage, ignore 
        end)
    end,
    Receive = function(self, len, ply) -- what to do when server receives click
        local terminal = net.ReadEntity() -- reads terminal
        if (!self:Filter(terminal, ply)) then return end
        local text = net.ReadString() -- readstring sent from above ^
        terminal:SetTerminalName(text) -- set terminal name
    end


})

if (SERVER) then
    util.AddNetworkString("beginUse")
    util.AddNetworkString("stopUse")
    util.AddNetworkString("terminalUpdate")
    util.AddNetworkString("updateGBP")
    util.AddNetworkString("requestUnit")

    function ENT:Initialize()
        self:SetModel( "models/props/cs_office/tv_plasma.mdl" )
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid(SOLID_VPHYSICS)
        self:SetMaterial("phoenix_storms/metalset_1-2")
        self:SetColor(Color(71, 71, 71, 255))
    end 

    function ENT:Think()
        if (not IsValid(self.currentUser)) then
            self.beingUsed = false
            self.currentUser = nil 
            self.currentID = nil 
            return
        end
        if (self.beingUsed and self.currentUser) then
            if (self.currentUser:GetPos():Distance(self:GetPos()) > 100) then -- if over 100 units, do this
                self.beingUsed = false
                self.currentUser = nil
                self.currentID = nil
                net.Start("terminalUpdate")
                net.WriteEntity(self)
                net.WriteBool(false)
                net.WriteEntity(nil)
                net.Broadcast()
            end
        end
    end

    net.Receive("beginUse", function(len, ply)
        terminal = net.ReadEntity()
        if not terminal.beingUsed then
            terminal.currentUser = ply
            terminal.beingUsed = true
            net.Start("terminalUpdate")
            net.WriteEntity(terminal)
            net.WriteBool(true)
            net.WriteEntity(ply)
            net.Broadcast()
        end
    end)

    net.Receive("stopUse", function(len,ply)
        terminal = net.ReadEntity()
        if terminal.beingUsed and terminal.currentUser == ply then
            terminal.beingUsed = false
            terminal.currentUser = nil
            terminal.currentID = nil
            net.Start("terminalUpdate")
            net.WriteEntity(terminal)
            net.WriteBool(false)
            net.WriteEntity(nil)
            net.Broadcast()
        end
    end)

    net.Receive("requestUnit", function(len, ply)
        terminal = net.ReadEntity()
        text = net.ReadString()
        if terminal.currentUser ~= ply then return end
        if ply:IsCombine() then return end

        ix.chat.Add(ply, "request", text)
        ix.chat.Add(ply, "request_eavesdrop", text)
    end)

    net.Receive("updateGBP", function(len, ply)
        if not ply:IsCombine() then return end
        local terminal = net.ReadEntity()
        local isChanging = net.ReadBool()
        local amount = net.ReadInt(32)

        if isChanging then
            terminal.currentID.data.loyalty.points = amount
        else
            terminal.currentID.data.loyalty.points = terminal.currentID.data.loyalty.points + amount
        end

    end)
end

if (CLIENT) then
    NORMALMODE = 1 --set variables with value 1,2,3 (made to make the menu easier to understand, thanks liquid)
    CITIZENMODE = 2
    POLICEMODE = 3

    function ENT:Think()
        if not self.initialize then
            self.initialize = true
            self.currentUser = nil
            self.currentID = nil
            self.beingUsed = false
            self.matInsignia = Material("aerolace/insignia.png")
            self.scale = 0.1
            self.currentState = NORMALMODE --currentState = 1
        end
    end 

    function ENT:MakeNoise()
        self:EmitSound("soundname", self:GetPos(), self, CHAN_AUTO, 1)
    end
    
    function ENT:Beep()
        self:EmitSound("Grenade.Blip", self:GetPos(), self, CHAN_AUTO, 1) -- modify later
    end

    function ENT:BadNoise()
        self:EmitSound("soundname", self:GetPos(), self, CHAN_AUTO, 1)
    end

    function ENT:StopUsing()
        net.Start("stopUse")
        net.WriteEntity(self)
        net.SendToServer()
    end

    function ENT:BeginUsing()
        net.Start("beginUse")
        net.WriteEntity(self)
        net.SendToServer()
    end

    function ENT:RenderTop()
        surface.SetDrawColor( 255,255,255, 255 )
        imgui.skin.foreground = Color(108,147,255, 255)
        if self:GetTerminalName() ~= nil then
            local terminalName = self:GetTerminalName()
            if imgui.xTextButton("c17 - " .. self:GetTerminalName(), "!Roboto@30", 0 / self.scale, 1.25 / self.scale, 32 / self.scale, 2 / self.scale) then
                self.currentState = NORMALMODE -- mode = 1
                self:Beep() --though it seems arbitrary to saving data, i think it'd be better to just have this written as a function like how liquid did with self:Beep()
                self:StopUsing()
            end
        else
            imgui.xTextButton("c17 - Terminal", "!Roboto@30", 0 / self.scale, 1.25 / self.scale, 32 / self.scale, 2 / self.scale)
        end
    end

    function ENT:CardMenu(terminal, cardsList)
        local menuTable = {}
        for key, card in pairs(cardsList) do
            local cardName = card.data.name
            local cardID = card.data.id 
            local quickName = "Blank Card"
            if card.data.id ~= nil and card.data.name ~= nil then
                quickName = card.data.name .. ", #" .. card.data.id
            end
            menuTable[quickName] = function() --still scuffed, but not as bad as liquid's code :')
                local cardID = cardID
                local cardName = cardName
                local terminal = terminal
                if card ~= nil then
                    terminal.currentID = card -- make table 
                    terminal.currentState = LocalPlayer():IsCombine() and POLICEMODE or CITIZENMODE -- similar to if then do or not then do
                    terminal:BeginUsing() --gives player and terminal with terminal:BeginUsing and player with net.Start() 
                end

            end

        end
        
        return menuTable
    end

    function ENT:RenderNormal() -- render when there is nothing going on

        self:RenderTop() -- base
        surface.SetDrawColor(255,255,255,255)
        surface.SetMaterial(self.matInsignia)
        surface.DrawTexturedRect( 
            6 / self.scale, 10 / self.scale, 
            15 / self.scale, 20 / self.scale 
        )
         --alpha 255, shown
        imgui.skin.border = Color(255,255,255,255) --alpha 0, not shown
        imgui.skin.borderHover = Color(0,0,0,0) --alpha 0, not shown
        imgui.skin.foreground = Color(255,255,255,255) --left off here, go look at shit before continuing you tired ass retard

        if self.beingUsed and self.currentUser ~= LocalPlayer() then
            imgui.xTextButton("In use by " .. self.currentUser:Name() .. "...", "!Roboto@20", 10 / self.scale, 10 / self.scale, 32 / self.scale, 2 / self.scale) -- in use by PLAYERNAME, fix this 
        else
            if imgui.xTextButton("[Request Unit]","!Roboto@40", 25 / self.scale, 20 / self.scale, 32 / self.scale, 2 / self.scale, 1 / self.scale) then
                Derma_StringRequest("Request Authority", "Request:", "", function(text)
                
                    net.Start("requestUnit")
                    net.WriteEntity(self)
                    net.WriteString(text)
                    net.SendToServer()
                    self.currentID = nil
                    self:StopUsing()

                end)
            end

            if imgui.xTextButton("[Insert ID]","!Roboto@40", 25 / self.scale, 15 / self.scale, 32 / self.scale, 2 / self.scale) then

                local count = 0
                local cards = {}
                local cardList = {}
                local char = LocalPlayer():GetCharacter()
                for space,item in pairs(char:GetInventory():GetItems()) do
                    
                    if item.uniqueID == "cid" then
                        count = count + 1
                        table.insert(cards, item)
                    elseif item.base == "base_bags" then
                        for k, v in pairs(item:GetInventory():GetItems()) do
                            if v.uniqueID == "cid" then
                                count = count + 1
                                table.insert(cards, v)
                            end
                        end
                    end
                end
                if count == 0 then
                    self:Beep()
                elseif count == 1 then
                    self.currentID = cards[1]
                    self.currentState = LocalPlayer():IsCombine() and POLICEMODE or CITIZENMODE
                    self:BeginUsing()
                elseif count > 1 then
                    local menuTable = self:CardMenu(self, cards)

                    ix.menu.Open(menuTable)

                end
            end
        end
    end

    function ENT:RenderCitizen() -- render when citizen has inserted their id 

        self:RenderTop()
        surface.SetDrawColor(0,0,0,255)
        --if self.currentUser ~= nil then print("currentUser valid") end
        --if self.currentID ~= nil then print("currentID valid") end
        if self.currentUser ~= nil and self.currentID.data.id ~= nil then 
            imgui.xTextButton("Welcome, " .. currentID.data.name .. ".", "!Futura@30", 10 / self.scale, 10 / self.scale, 32 / self.scale, 2 / self.scale) --terminal fucky wucky? idk
            imgui.xTextButton("Loyalty Points: " .. self.currentID.data.loyalty.points, "!Futura@30", 10 / self.scale, 15 / self.scale, 32 / self.scale, 2 / self.scale)
        elseif self.currentUser ~= nil and self.currentID.data.id == nil then
            imgui.xTextButton("Blank Card - No Data Detected.", "!Futura@30", 10 / self.scale, 10 / self.scale, 32 / self.scale, 2 / self.scale) --terminal fucky wucky? idk
        end
        
    end

    function ENT:RenderPolice() -- render when a cca inserts someone's id 

        self:RenderTop()
        if self.currentUser ~= nil and self.currentID.data.id ~= nil then
            imgui.xTextButton(currentID.data.name, "!Futura@20", 10 / self.scale, 10 / self.scale, 32 / self.scale, 2 / self.scale)
            imgui.xTextButton("LP - " .. currentID.data.loyalty.points, "!Futura@20", 10 / self.scale, 15 / self.scale, 32 / self.scale, 2 / self.scale)
            if imgui.xTextButton("[Change Points]") then
                if not LocalPlayer():IsCombine() then return end
                Derma_StringRequest("Set Loyalty Points", "Points:", currentID.data.loyalty.points, function(text)

                    num = tonumber(text)
                    if !num then return end
                    net.Start("updateGBP")
                    net.WriteEntity(self)
                    net.WriteBool(true)
                    net.WriteInt(num, 32)
                    net.SendToServer()

                end) 
            end

        elseif self.currentID.data.id == nil and self.currentUser ~= nil then
            if imgui.xTextButton("Write Transfer Card", "!Futura@20", 10 / self.scale, 10 / self.scale, 32 / self.scale, 2 / self.scale) then
                local menuTable = {}
                for space, item in pairs(self.currentUser:GetCharacter():GetInventory():GetItems()) do
                    if item.uniqueID == "transfer_card" then
                        menuTable[item] = function()
                            self.currentID.data.id = Schema:ZeroNumber(math.random(00000,99999), 5)
                            self.currentID.data.name = item.data.name
                        end
                    elseif item.base == "base_bags" then
                        for space, itemTwo in pairs(item:GetInventory():GetItems()) do
                            if itemTwo.uniqueID = "transfer_card" then
                                str = itemTwo.data.name .. ", #" .. itemTwo.data.cid
                                menuTable[] = function() 
                                self.currentID.data.id = Schema:ZeroNumber(math.random(00000,99999), 5)
                                self.currentID.data.name = itemTwo.data.name
                                end
                            end
                        end
                    end
                end
            end
        end

    end

    function ENT:CheckUpdate()
        self.beingUsed = net.ReadBool()
        self.currentUser = net.ReadEntity()
    end

    net.Receive("terminalUpdate", function(len,ply)
        local terminal = net.ReadEntity()
        print(terminal)
        if terminal.CheckUpdate then --function returns true if it ran without error, so this might mean if it was successful (?)
            terminal.beingUsed = net.ReadBool()
            terminal.currentUser = net.ReadEntity()
            if not terminal.beingUsed then
                terminal.currentState = NORMALMODE
            end
        end
    end)


    function ENT:Draw()
        self:DrawModel()
        if EyePos():Distance(self:GetPos()) > 1000 then return end -- if eyes are more than 1000 units away, don't draw
        if not self.initialize then return end -- if not initialized, don't draw
        if imgui.Entity3D2D(self, Vector(7.5, -28, 36), Angle(0, 90, 90), self.scale, 1000, 150) then --self, position, angle, scale
            surface.SetDrawColor( 0,0,0, 255 )
            surface.DrawRect( 0, 0, 56 / self.scale, 34 / self.scale )

            if self.beingUsed and self.currentUser ~= LocalPlayer() then
                self.currentState = NORMALMODE
            end
            
            self.combineMaterial = self.combineMaterial or 
                Material("models/props_combine/com_shield001a")
            --models/rendertarget
            surface.SetDrawColor( 0, 150, 255, 255 )
            surface.SetMaterial(self.combineMaterial)
            surface.DrawTexturedRect(0, 0, 56 / self.scale, 34 / self.scale)
            surface.SetDrawColor( 0, 0, 0, 246 )
            surface.DrawRect( 0, 0, 56 / self.scale, 34 / self.scale )

            if self.currentState == NORMALMODE then
                self:RenderNormal()
            elseif self.currentState == CITIZENMODE then
                self:RenderCitizen()
            elseif self.currentState == POLICEMODE then
                self:RenderPolice()
            end
            
            imgui.End3D2D()
        end
    end
end