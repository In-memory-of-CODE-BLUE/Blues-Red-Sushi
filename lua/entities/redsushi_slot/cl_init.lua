include("shared.lua")
include("config_redsushi.lua")


local mascot = Material("redsushi/mascot.png", "noclamp smooth") 
local mascot_eye = Material("redsushi/mascot_eye.png") 
local mascot_angry = Material("redsushi/mascot_angry.png", "noclamp smooth") 

surface.CreateFont( "RedSushi1", {
	font = "Arial",
	extended = false,
	size = 20,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

surface.CreateFont( "RedSushi3", {
	font = "Arial",
	extended = false,
	size = 30,
	weight = 800,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

surface.CreateFont( "RedSushi2", {
	font = "Arial",
	extended = false,
	size = 55,
	weight = 800,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

surface.CreateFont( "RedSushi4", {
	font = "Arial",
	extended = false,
	size = 25,
	weight = 800,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

surface.CreateFont( "RedSushi5", {
	font = "Arial",
	extended = false,
	size = 44,
	weight = 800,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

local function Berp(s, e, v)
	v = (math.sin(v * math.pi * (0.2 + 2.5 * v * v * v)) * math.pow(1 - v, 2.2) + v) * (1 + (1.2 * (1 - v)))
	return s + (e - s) * v
end

function ENT:Initialize()
	--Setup our reels
	self:SetupReels()

	self.lerpedPayAmount = 0

	self.toggledRedmode = false

	self.angryMascotOffset = Vector(0,0,0)

	self.eyeDirection = Vector(0,0,0)
end

--Takes a vector and returns a world offset position
--relative to the entity
function ENT:WorldOffset(vector)
	local newVec = Vector(0,0,0)

	--Offset it by our angles
	newVec = newVec + (self:GetAngles():Right() * vector.x)
	newVec = newVec + (self:GetAngles():Up() * vector.y)
	newVec = newVec + (self:GetAngles():Forward() * vector.z)

	--convert to world
	newVec = newVec + self:GetPos() 

	--return it
	return newVec
end

--This function will create 3 clientside models
--These models are the reels.
function ENT:SetupReels()
	if self.reels ~= nil then
		for k, v in pairs(self.reels) do
			if IsValid(v.model) then v.model:Remove() end
		end
	end

	self.reels = {} 
	self.reels[1] = {}
	self.reels[1].shouldSpin = false
	self.reels[1].direction = false
	self.reels[1].model = ClientsideModel("models/redsushi/reel.mdl", RENDERGROUP_OPAQUE)
	self.reels[1].model:SetPos(self:WorldOffset(Vector(-5.5,57,0)))
	self.reels[1].model:SetAngles(self:GetAngles())

	self.reels[2] = {}
	self.reels[2].shouldSpin = false
	self.reels[2].direction = true
	self.reels[2].model = ClientsideModel("models/redsushi/reel.mdl", RENDERGROUP_OPAQUE)
	self.reels[2].model:SetPos(self:WorldOffset(Vector(0.1,57,0)))
	self.reels[2].model:SetAngles(self:GetAngles())

	self.reels[3] = {}
	self.reels[3].shouldSpin = false
	self.reels[3].direction = false
	self.reels[3].model = ClientsideModel("models/redsushi/reel.mdl", RENDERGROUP_OPAQUE)
	self.reels[3].model:SetPos(self:WorldOffset(Vector(5.67,57,0)))
	self.reels[3].model:SetAngles(self:GetAngles())

	self.reels[1].model:SetParent(self)
	self.reels[2].model:SetParent(self)
	self.reels[3].model:SetParent(self)
end

function ENT:Draw()
	self:DrawModel()

	if not IsValid(self.reels[1].model) then
		self:SetupReels()
	end

	local ang = self:GetAngles()

	ang:RotateAroundAxis(self:GetAngles():Up(),-90)
	ang:RotateAroundAxis(ang:Forward(), 90)

	--Graphic 2
	cam.Start3D2D(self:WorldOffset(Vector(-12.3,76.6,-6.12)), ang, 0.05)
		--draw.RoundedBox(4,0,0, 490, 290, Color(255,255,255,100))
		if not self:GetIsRedScreen() then
			--Draw the mascot happy
			surface.SetMaterial(mascot)
			surface.SetDrawColor(Color(255,255,255,255))
			surface.DrawTexturedRect(15 + 20,5,200, 200)

			--Now draw the eye
			local eyeOneBasePos = Vector(83,121,0)
			local eyeTwoBasePos = Vector(172,119, 0)

			--Calculate the offset
			local eyeDirectionOne =  self:WorldToLocal(LocalPlayer():EyePos())
			eyeDirectionOne.z = eyeDirectionOne.z - 63.86

			eyeDirectionOne.y = Lerp(((eyeDirectionOne.y - 10 + 50) / (50 * 2)), -1, 1)
			eyeDirectionOne.z = Lerp(((eyeDirectionOne.z + 36) / (36 * 2)), -1, 1)

			local scaledOffset = eyeDirectionOne
			scaledOffset.y = scaledOffset.y * 4
			scaledOffset.z = scaledOffset.z * 10

			local eyeDirectionTwo =  self:WorldToLocal(LocalPlayer():EyePos())
			eyeDirectionTwo.z = eyeDirectionTwo.z - 63.86

			eyeDirectionTwo.y = Lerp(((eyeDirectionTwo.y - 10 + 50) / (50 * 2)), -1, 1)
			eyeDirectionTwo.z = Lerp(((eyeDirectionTwo.z + 36) / (36 * 2)), -1, 1)

			local scaledOffset2 = eyeDirectionTwo
			scaledOffset2.y = scaledOffset2.y * 3
			scaledOffset2.z = scaledOffset2.z * 9

			surface.SetMaterial(mascot_eye)
			surface.SetDrawColor(Color(255,255,255,255))
			surface.DrawTexturedRectRotated(83 - scaledOffset.y  + 20,121 - scaledOffset.z,22, 22, 0)

			surface.SetMaterial(mascot_eye)
			surface.SetDrawColor(Color(255,255,255,255))
			surface.DrawTexturedRectRotated(130 - scaledOffset2.y + 20,116 - scaledOffset2.z,18, 18, 0) 

		else
			--Draw the mascot angry and shaking
			surface.SetMaterial(mascot_angry)
			surface.SetDrawColor(Color(255,255,255,255))
			surface.DrawTexturedRect(15 + math.random(-5, 5),5 + math.random(-5, 5),200, 200)			
		end

		--Draw credit value
		draw.SimpleText("$"..string.Comma(REDSUSHI.CONFIG.CreditValue), "RedSushi2", 375, 133, Color(255, 255, 255), 1, 1)

		--Draw win amount
		draw.SimpleText(self:GetWinAmount().." CR", "RedSushi1", 68, 266, Color(247, 280, 65), 1, 1)

		--Draw paid amount
		draw.SimpleText(math.ceil(self.lerpedPayAmount).." CR", "RedSushi1", 185, 266, Color(247, 280, 65), 1, 1)

		--Draw bet amount
		draw.SimpleText(self:GetBetAmount().." CR", "RedSushi1", 305, 266, Color(247, 280, 65), 1, 1)

		--Draw money in credits
		draw.SimpleText(math.floor(LocalPlayer():getDarkRPVar("money") / REDSUSHI.CONFIG.CreditValue).." CR", "RedSushi1", 424, 266, Color(247, 280, 65), 1, 1)
	

		if self:GetIsJackpotScreen() then
			draw.RoundedBox(0,0,0,495,295,Color(30,30,30))
 
			if self.dollars == nil then
				self.dollars = {}
				for i = 1, 32 do
					self.dollars[i] = {}
					self.dollars[i].x = math.random(5, 490)
					self.dollars[i].y = math.random(5, 295)
					self.dollars[i].curTimeOffset = math.random(0.1, 10.5)
					self.dollars[i].font = table.Random({"RedSushi2", "RedSushi3"})
					self.dollars[i].speed = math.random(50, 175)
				end
			end

			for i = 1 , 32 do
				self.dollars[i].y = self.dollars[i].y - (self.dollars[i].speed * FrameTime())
				if self.dollars[i].y < 0 then
					self.dollars[i].y = 295
					self.dollars[i].x = math.random(5, 490)
				end

				--Draw the dollar
				draw.SimpleText("$", self.dollars[i].font, self.dollars[i].x +(math.sin((CurTime() + self.dollars[i].curTimeOffset) * 5) * (self.dollars[i].speed / 10)) ,  self.dollars[i].y, Color(95, 147, 65), 1, 1)
			
				

			end

			draw.RoundedBox(8, 40, 40, 495 - 43 - 40, 290 - 38 - 40, Color(130,130,130, 200))

			draw.SimpleText("Congratulations!", "RedSushi3", 495 / 2, 70, Color(0,0,0), 1, 1)
			
			draw.SimpleText("You've won: $"..string.Comma(self:GetWinAmount() * REDSUSHI.CONFIG.CreditValue)..".00", "RedSushi4", 495 / 2, 105, Color(0,0,0), 1, 1)
			draw.SimpleText("Call an attendant", "RedSushi4", 495 / 2, 105 + 30, Color(0,0,0), 1, 1)
			draw.SimpleText("to validate your", "RedSushi4", 495 / 2, 105 + 60, Color(0,0,0), 1, 1)
			draw.SimpleText("win so that you may", "RedSushi4", 495 / 2, 105 + 90, Color(0,0,0), 1, 1)
			draw.SimpleText("collect your winnings.", "RedSushi4", 495 / 2, 105 + 120, Color(0,0,0), 1, 1)
		end

	cam.End3D2D()

	--Graphic 3
	cam.Start3D2D(self:WorldOffset(Vector(-12.3,98.6,-5.6)), ang, 0.05)
		--Draw the paytable
		draw.SimpleText(REDSUSHI.CONFIG.Payouts.THREE_BAR * self:GetBetAmount().." CR", "RedSushi1", 98, 271, Color(247, 280, 65), 1, 1)
		draw.SimpleText(REDSUSHI.CONFIG.Payouts.THREE_CHERRY * self:GetBetAmount().." CR", "RedSushi1", 247, 271, Color(247, 280, 65), 1, 1)
		draw.SimpleText(REDSUSHI.CONFIG.Payouts.ANY_TWO_CHERRIES * self:GetBetAmount().." CR", "RedSushi1", 392, 271, Color(247, 280, 65), 1, 1)

		draw.SimpleText(REDSUSHI.CONFIG.Payouts.THREE_SEVENS * self:GetBetAmount().." CR", "RedSushi1", 98, 203, Color(247, 280, 65), 1, 1)
		draw.SimpleText(REDSUSHI.CONFIG.Payouts.THREE_BARBARBAR * self:GetBetAmount().." CR", "RedSushi1", 247, 203, Color(247, 280, 65), 1, 1)
		draw.SimpleText(REDSUSHI.CONFIG.Payouts.THREE_BARBAR * self:GetBetAmount().." CR", "RedSushi1", 392, 203, Color(247, 280, 65), 1, 1)

		draw.SimpleText(REDSUSHI.CONFIG.Payouts.THREE_JACKPOTS * self:GetBetAmount().." CR", "RedSushi1", 247, 121, Color(247, 280, 65), 1, 1)
	cam.End3D2D()
end

function ENT:Think()
	for k,v in pairs(self.reels) do
		if v.shouldSpin and IsValid(v.model) then
			local a = v.model:GetAngles()

			if not v.direction then
				a:RotateAroundAxis(self:GetAngles():Right(), 1000 * FrameTime())
			else
				a:RotateAroundAxis(self:GetAngles():Right(), 1000 * -FrameTime())
			end
			v.model:SetAngles(a)
		end

		if v.isAnimating and IsValid(v.model) then

			v.model:SetLocalAngles(Angle(Berp(v.startAng, v.target, (CurTime() - v.startTime) * 4),0,0))
			if CurTime() - v.startTime >= 0.25 then
				v.model:SetLocalAngles(Angle(v.target,0,0)) 
				v.isAnimating = false
			end
		end
	end

	if self:GetIsRedScreen() and self.toggledRedmode == false then
		--Update the materials of all the lights

	end 

	if self:GetWinAmount() > 0 then
		if self:GetWinAmount() < 20 then
			self.lerpedPayAmount = Lerp(2 * FrameTime(), self.lerpedPayAmount, self:GetWinAmount())
		else
			self.lerpedPayAmount = Lerp(1 * FrameTime(), self.lerpedPayAmount, self:GetWinAmount())
		end

		if math.abs(self.lerpedPayAmount - self:GetWinAmount()) < 1 then
			self.lerpedPayAmount = self:GetWinAmount()
		end
	else
		self.lerpedPayAmount = 0
	end
end

--When called, the reels will start spinning for ever
--until StopSpinning(reel, index) is called.
function ENT:StartSpinning()
	for k,v in pairs(self.reels) do
		v.shouldSpin = true
		v.model:SetMaterial("redsushi/redsushi_reel_blur", true)
	end
end


function ENT:StopSpinning(reel, index)
	self.reels[reel].model:SetParent(self)

	self.reels[reel].shouldSpin = false	
	self.reels[reel].model:SetMaterial("redsushi/redsushi_reel", true)

	--Now work out our rotation
	local rotation = math.Round((index / 16.0) * 360.0)
	--self.reels[reel].model:SetP
	self.reels[reel].model:SetLocalAngles(Angle(rotation, 0, 0))

	--Set up animation
	self.reels[reel].isAnimating = true
	self.reels[reel].target = rotation
	if not self.reels[reel].direction then
		self.reels[reel].startAng = rotation - 45
	else
		self.reels[reel].startAng = rotation + 45
	end

	self.reels[reel].startTime = CurTime()
end

function ENT:OnRemove()
	for k,v in pairs(self.reels) do
		v.model:Remove()
	end
end

net.Receive("REDSUSHI_STOP_REEL", function()
	local e = net.ReadEntity()
	local reel = net.ReadInt(8)
	local index = net.ReadInt(8)

	if e:IsValid() then
		e:StopSpinning(reel, index)
	end
end)

net.Receive("REDSUSHI_START_SPIN", function()
	local e = net.ReadEntity()

	if e:IsValid() then
		e:StartSpinning()
	end
end)

net.Receive("REDSUSHI_TOGGLE_REEL_LIGHTS", function()
	local state = net.ReadBool()
	local ent = net.ReadEntity()

	if IsValid(ent) and ent.reels ~= nil then
		if state then
			for k, v in pairs(ent.reels) do
				v.model:SetMaterial("redsushi/redsushi_reel_flash")
			end
		else
			for k, v in pairs(ent.reels) do
				v.model:SetMaterial("redsushi/redsushi_reel")
			end
		end
	end
end)

local function round(what ,  precision)
	return math.floor(what*math.pow(10,precision)+0.5) / math.pow(10,precision)
end

net.Receive("REDSUSHI_EDIT_CHANCES", function()

	local e = net.ReadEntity()
	local chances = net.ReadTable()

	local f = vgui.Create("DFrame")
	f:SetSize(352, 539)
	f:Center()
	f:ShowCloseButton(false)
	f:SetTitle("")
	f.Paint = function(s, w, h)
		draw.RoundedBox(0, 0,0,w,h,Color(65,65,65))
		draw.RoundedBox(0, 0,0,w,63,Color(255,102,0))

		local totalChance = 0
		for i = 0 , 6 do
			totalChance = totalChance + chances[i]
		end

		--Draw the text in the top
		draw.SimpleText("RED SUSHI","RedSushi5",15, 9,Color(255,255,255))

		draw.SimpleText("JACKPOT","RedSushi3",15, 74,Color(255,102,0))
		draw.SimpleText(round(100.0 / totalChance * chances[0], 2).."%","RedSushi1",255, 83 + (38 * 0),Color(101,101,101), 2)

		draw.SimpleText("CHERRY","RedSushi3",15, 74 + (38 * 1),Color(255,102,0))
		draw.SimpleText(round(100.0 / totalChance * chances[1], 2).."%","RedSushi1",255, 83 + (38 * 1),Color(101,101,101), 2)

		draw.SimpleText("SEVEN","RedSushi3",15, 74 + (38 * 2),Color(255,102,0))
		draw.SimpleText(round(100.0 / totalChance * chances[2], 2).."%","RedSushi1",255, 83 + (38 * 2),Color(101,101,101), 2)

		draw.SimpleText("BAR","RedSushi3",15, 74 + (38 * 3),Color(255,102,0))
		draw.SimpleText(round(100.0 / totalChance * chances[3], 2).."%","RedSushi1",255, 83 + (38 * 3),Color(101,101,101), 2)

		draw.SimpleText("BAR BAR","RedSushi3",15, 74 + (38 * 4),Color(255,102,0))
		draw.SimpleText(round(100.0 / totalChance * chances[4], 2).."%","RedSushi1",255, 83 + (38 * 4),Color(101,101,101), 2)

		draw.SimpleText("BAR BAR BAR","RedSushi3",15, 74 + (38 * 5),Color(255,102,0))
		draw.SimpleText(round(100.0 / totalChance * chances[5], 2).."%","RedSushi1",255, 83 + (38 * 5),Color(101,101,101), 2)

		draw.SimpleText("VOID","RedSushi3",15, 74 + (38 * 6),Color(255,102,0))
		draw.SimpleText(round(100.0 / totalChance * chances[6], 2).."%","RedSushi1",255, 83 + (38 * 6),Color(101,101,101), 2)

		draw.SimpleText("REDSCREEN","RedSushi3",15, 74 + (38 * 7),Color(255,102,0))
		draw.SimpleText("RE-TRIG RED","RedSushi3",15, 74 + (38 * 8),Color(255,102,0))
	end

	--Create all the entry boxes
	for i = 1 , 9 do
		local text = vgui.Create("DTextEntry", f)
		text:SetPos(266, 79 + (38 * (i-1)))
		text:SetSize(70,26)
		if i < 8 then
			text:SetText(chances[i-1])
			text.OnChange = function(s)
				local num = math.ceil(tonumber(s:GetText()) or 1)
				if num > 0 then
					chances[i - 1] = num
				else
					chances[i - 1] = 1
				end
			end
		end

		if i == 8 then
			text:SetText(chances.RedscreenChance)
			text.OnChange = function(s)
				local num = math.ceil(tonumber(s:GetText()) or 0)
				if num > 0 then
					chances[i - 1] = num
				else
					chances[i - 1] = 0
				end
				
				num = math.Clamp(num, 0, 100)

				chances.RedscreenChance = num
			end
		end

		if i == 9 then
			text:SetText(chances.RedscreenRetriggerChance)
			text.OnChange = function(s)
				local num = math.ceil(tonumber(s:GetText()) or 0)
				if num > 0 then
					chances[i - 1] = num
				else
					chances[i - 1] = 0
				end
				
				num = math.Clamp(num, 0, 100)

				chances.RedscreenRetriggerChance = num
			end
		end
	end

	--Create the cancel button
	local cancel = vgui.Create("DButton", f)
	cancel:SetPos(16, 423)
	cancel:SetSize(321, 46)
	cancel:SetText("")
	cancel.Paint = function(s , w, h)
		draw.RoundedBox(0, 0, 0, w , h, Color(201,60,60))
		draw.SimpleText("CANCEL","RedSushi5",w/2, h/2,Color(255,255,255), 1, 1)
	end
	cancel.DoClick = function() f:Close() end

	local update = vgui.Create("DButton", f)
	update:SetPos(16, 480)
	update:SetSize(321, 46)
	update:SetText("")
	update.Paint = function(s , w, h)
		draw.RoundedBox(0, 0, 0, w , h, Color(255,102,0))
		draw.SimpleText("UPDATE","RedSushi5",w/2, h/2,Color(255,255,255), 1, 1)
	end
	update.DoClick = function() 
		net.Start("REDSUSHI_EDIT_CHANCES")
		net.WriteEntity(e)
		net.WriteTable(chances)
		net.SendToServer()

		f:Close()
	end


	f:MakePopup()
end)