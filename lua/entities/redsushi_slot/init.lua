AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

util.AddNetworkString("REDSUSHI_START_SPIN")
util.AddNetworkString("REDSUSHI_STOP_REEL")
util.AddNetworkString("REDSUSHI_TOGGLE_REEL_LIGHTS")
util.AddNetworkString("REDSUSHI_EDIT_CHANCES")

sound.Add( {
	name = "redsushi_reel_spin_motor",
	channel = CHAN_STATIC,
	volume = 1,
	level = 55,
	pitch = { 99, 101 },
	sound = "redsushi/spinning.mp3"
} ) 

sound.Add( {
	name = "redsushi_bell",
	channel = CHAN_STATIC,
	volume = 1,
	level = 55,
	pitch = { 99, 101 },
	sound = "redsushi/redsceen_bell.mp3"
} ) 


function ENT:Initialize()
	self:SetModel("models/redsushi/machine.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType(SIMPLE_USE)
 
	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake() 
	end

	--Just some vars
	self:SetIsRedScreen(false)
	self:SetIsJackpotScreen(false)
	self.isSpinning = false
	self:SetBetAmount(1)

	--This creates a copy of the default chances on the entity, this can overridden of course
	self.chances = table.Copy(REDSUSHI.CONFIG.DefaultChances)
	self.chances.RedscreenChance = REDSUSHI.CONFIG.RedscreenChance
	self.chances.RedscreenRetriggerChance = REDSUSHI.CONFIG.RedscreenRetriggerChance

	--This will contain the info about the last win, used by the redscreen to know which win to give them next
	self.lastWinAmount = nil

	self.soundPlaying = false
end

function ENT:OnRemove()
	if self.spinner ~= nil then
		self.spinner.redsushimachine = nil
		self.spinner = nil	
	end
end

--When called will return a ID and index for the symbol.
function ENT:GenerateItem()
	--Loop over items and create the chances
	local totalChance = 0
	for k ,v in pairs(REDSUSHI.CONFIG.DefaultChances) do
		if not isnumber(k) or k > 6 then continue end
		totalChance = totalChance + v
	end
	
	local num = math.random(1 , totalChance)
	local prevCheck = 0
	local curCheck = 0
	local index = nil

	for k ,v in pairs(REDSUSHI.CONFIG.DefaultChances) do
		if not isnumber(k) or k > 6 then continue end 
		if num >= prevCheck and num <= prevCheck + v then
			index = k
		end
		prevCheck = prevCheck + v
	end

	--return the result

	if index ~= nil then
		return index
	else
		for k, v in pairs(player.GetAll()) do
			v:ChatPrint("[RED SUSHI] WARNING! - This should never happen, if it has contact <CODE BLUE> or SUSHIMISO!")
		end

		return REDSUSHI.Symbols.VOID --Return void if no index found
	end
end

function ENT:StopReel(reel, symbol)
	net.Start("REDSUSHI_STOP_REEL")
	net.WriteEntity(self)
	net.WriteInt(reel, 8)
	net.WriteInt(symbol, 8)
	net.Broadcast()
end

function ENT:TriggerRedscreen(winAmount)
	self:SetSubMaterial(6, "redsushi/redsushi_lightring_red")
	self:SetSubMaterial(3, "redsushi/redsushi_graphic_1_red")
	self:SetSubMaterial(2, "redsushi/redsushi_graphic_2_red")
	self:SetSubMaterial(7, "redsushi/redsushi_graphics_3_red")

	if not self.soundPlaying then
		self.soundPlaying = true
		self:EmitSound("redsushi_bell")
	end

	self:SetIsRedScreen(true)

	timer.Simple(1, function()
		self:StartFreeSpin(self.spinner, winAmount)
	end)
end

function ENT:StopRedscreen()
	self:SetSubMaterial(6, "redsushi/redsushi_lightring")
	self:SetSubMaterial(3, "redsushi/redsushi_graphic_1")
	self:SetSubMaterial(2, "redsushi/redsushi_graphic_2")
	self:SetSubMaterial(7, "redsushi/redsushi_graphics_3")
	self:SetIsRedScreen(false)

	if self.soundPlaying then
		self:StopSound("redsushi_bell")
		self.soundPlaying = false
	end
	 
end

function ENT:StopJackpot()
	self:SetSubMaterial(6, "redsushi/redsushi_lightring")
	self:SetSubMaterial(3, "redsushi/redsushi_graphic_1")
	self:SetSubMaterial(2, "redsushi/redsushi_graphic_2")
	self:SetSubMaterial(7, "redsushi/redsushi_graphics_3")

	net.Start("REDSUSHI_TOGGLE_REEL_LIGHTS")
	net.WriteBool(false)
	net.WriteEntity(self)
	net.Broadcast()

	self:SetIsRedScreen(false)
	self:StopSound("redsushi_bell")

	self:SetIsJackpotScreen(false)

	self.isSpinning = false

end

function ENT:TriggerJackpot()
	self:SetSubMaterial(6, "redsushi/redsushi_lightring_gold")
	self:SetSubMaterial(3, "redsushi/redsushi_graphic_1")
	self:SetSubMaterial(2, "redsushi/redsushi_graphic_2")
	self:SetSubMaterial(7, "redsushi/redsushi_graphics_3")

	self:SetIsJackpotScreen(true)

	net.Start("REDSUSHI_TOGGLE_REEL_LIGHTS")
	net.WriteBool(true)
	net.WriteEntity(self)
	net.Broadcast()

	self:EmitSound("redsushi/jackpot.mp3")

	timer.Simple(14, function()
		self:StopJackpot()
	end)

end
 
function ENT:TriggerWinscreen(amount)
	self:SetSubMaterial(6, "redsushi/redsushi_lightring_green")
	self:SetWinAmount(amount)
	local time = 2
	if amount >= REDSUSHI.CONFIG.LargePayoutThreshold then
		self:EmitSound("redsushi/payout_big.mp3")
		time = 4 
	else
		self:EmitSound("redsushi/payout.mp3")
	end

	net.Start("REDSUSHI_TOGGLE_REEL_LIGHTS")
	net.WriteBool(true)
	net.WriteEntity(self)
	net.Broadcast()


	timer.Simple(time, function()
		self.isSpinning = false
		self:SetSubMaterial(6, "redsushi/redsushi_lightring")

		net.Start("REDSUSHI_TOGGLE_REEL_LIGHTS")
		net.WriteBool(false)
		net.WriteEntity(self)
		net.Broadcast()
	end)
end

function ENT:StartFreeSpin(ply, previousWinAmount)
	self.isSpinning = true

	self.spinner = ply --(YOU GOT SPINNERS?)
	self.spinnerUpdate = CurTime()
	self.spinner.redsushimachine = self

	--Now we have our previous win amount, lets go ahead and find a win that is higher than this
	local previousCheckTable = nil
	local nextBest = nil

	for i = 1, #REDSUSHI.WinTable do

		if previousCheckTable == nil then
			previousCheckTable = REDSUSHI.WinTable[i]
		else
			if REDSUSHI.WinTable[i].pay * self:GetBetAmount() > previousWinAmount then
				previousCheckTable = REDSUSHI.WinTable[i]
			else
				nextBest = previousCheckTable
			end
		end
	end

	--Generate three items
	local item1 = table.Random(nextBest[1])
	local item2 = table.Random(nextBest[2])
	local item3 = table.Random(nextBest[3])

	if item1 == -1 then item1 = 1 end
	if item2 == -1 then item2 = 3 end
	if item3 == -1 then item3 = 5 end

	--Start spinning for everyone
	net.Start("REDSUSHI_START_SPIN")
	net.WriteEntity(self)
	net.Broadcast()

	self:EmitSound("redsushi_reel_spin_motor")

	--Now send the effects to the player
	timer.Simple(2, function()
		self:EmitSound("redsushi/stop1.mp3")
		--Generate where we should stop
		local stopIndex = table.Random(REDSUSHI.SymbolsToReelPosition[item1])
		self:StopReel(1, stopIndex)

		timer.Simple(2, function()
			self:EmitSound("redsushi/stop2.mp3")
			stopIndex = table.Random(REDSUSHI.SymbolsToReelPosition[item2])
			self:StopReel(2, stopIndex)

			timer.Simple(2, function()
				
				self:StopSound("redsushi_reel_spin_motor")

				stopIndex = table.Random(REDSUSHI.SymbolsToReelPosition[item3])
				self:StopReel(3, stopIndex)		

				--Did we win, if so what is the amount we won
				local isWin = REDSUSHI.IsWin(item1, item2, item3)

				if isWin ~= false then
					self:SetWinAmount(self:GetWinAmount() + (isWin.pay * self:GetBetAmount()))

					if item1 == REDSUSHI.Symbols.JACKPOT and item2 == REDSUSHI.Symbols.JACKPOT and item3 == REDSUSHI.Symbols.JACKPOT then
						self:StopRedscreen()
						self:TriggerJackpot()
						REDSUSHI.CONFIG.AddMoney(ply, isWin.pay * (REDSUSHI.CONFIG.CreditValue * self:GetBetAmount()))
						ply:ChatPrint("[SLOT] You won $"..(isWin.pay * REDSUSHI.CONFIG.CreditValue * self:GetBetAmount()).."!")
					else
						if self:GetWinAmount() >= REDSUSHI.CONFIG.SubJackpotValue then
							self:StopRedscreen()
							self:TriggerJackpot()
							REDSUSHI.CONFIG.AddMoney(ply, isWin.pay * (REDSUSHI.CONFIG.CreditValue * self:GetBetAmount()))
							ply:ChatPrint("[SLOT] You won $"..(isWin.pay * REDSUSHI.CONFIG.CreditValue * self:GetBetAmount()).."!")
						else

							if(math.random(0.000001, 99.99999999999)) <= REDSUSHI.CONFIG.RedscreenRetriggerChance then
								self:TriggerRedscreen(isWin.pay * self:GetBetAmount())
								self:EmitSound("redsushi/payout.mp3")
							else
								self:StopRedscreen()
								self:EmitSound("redsushi/payout.mp3")
								self:TriggerWinscreen(self:GetWinAmount())
							end

							REDSUSHI.CONFIG.AddMoney(ply, isWin.pay * (REDSUSHI.CONFIG.CreditValue * self:GetBetAmount()))
							ply:ChatPrint("[SLOT] You won $"..(isWin.pay * REDSUSHI.CONFIG.CreditValue * self:GetBetAmount()).."!")
						end
					end
				else
					self.isSpinning = false	
					self:EmitSound("redsushi/stop3.mp3")
					self:StopRedscreen()
					self:TriggerWinscreen(self:GetWinAmount())
					return
				end



				self:StopSound("redsushi_reel_spin_motor")
			end)	
		end)		
	end)
end

function ENT:StartSpin(ply)

	if ply:canAfford(REDSUSHI.CONFIG.CreditValue * self:GetBetAmount()) then
		REDSUSHI.CONFIG.TakeMoney(ply, (REDSUSHI.CONFIG.CreditValue * self:GetBetAmount()))
	else
		ply:ChatPrint("[SLOT] You cannot afford to use this machine, you need at least $"..REDSUSHI.CONFIG.CreditValue * self:GetBetAmount())
		return false
	end

	self.isSpinning = true
	self.spinner = ply --(YOU GOT SPINNERS?)
	self.spinnerUpdate = CurTime()
	self.spinner.redsushimachine = self

	--If this is true before the net messages
	--it will add an extra delay to the last reel to add suspense to the user
	local holdLastReel = false

	--Generate three items
	local item1 = self:GenerateItem()
	local item2 = self:GenerateItem()
	local item3 = self:GenerateItem()

	--If this is true the first 2 items are the same, lets give them a 1 in 4 chance to get the matching symbol 
	if item1 == item2 and item1 ~= 6 then
		if math.random(1, 4) == 2 then
			--Give them the matching item
			item3 = item1
		end
		holdLastReel = true
	end

	self:SetWinAmount(0)

	--Start spinning for everyone
	net.Start("REDSUSHI_START_SPIN")
	net.WriteEntity(self)
	net.Broadcast()

	self:EmitSound("redsushi/button_press.mp3")

	self:EmitSound("redsushi_reel_spin_motor") 

	--Now send the effects to the player
	timer.Simple(math.random(0.5, 1.1), function()

		--Generate where we should stop
		local stopIndex = table.Random(REDSUSHI.SymbolsToReelPosition[item1])

		self:StopReel(1, stopIndex)
		self:EmitSound("redsushi/stop1.mp3")

		timer.Simple(math.random(0.5, 1.1), function()
			local delay = 1
			self:EmitSound("redsushi/stop2.mp3")


			if holdLastReel then 
				delay = 3 
				self:EmitSound("redsushi/buildup.mp3")
			end

			stopIndex = table.Random(REDSUSHI.SymbolsToReelPosition[item2])
			self:StopReel(2, stopIndex)

			timer.Simple(delay, function()
				self:StopSound("redsushi_reel_spin_motor")

				stopIndex = table.Random(REDSUSHI.SymbolsToReelPosition[item3])
				self:StopReel(3, stopIndex)		

				--Did we win, if so what is the amount we won
				local isWin = REDSUSHI.IsWin(item1, item2, item3)
				 
				if isWin ~= false then
					self:SetWinAmount(REDSUSHI.CONFIG.CreditValue * self:GetBetAmount())
					
					if item1 == REDSUSHI.Symbols.JACKPOT and item2 == REDSUSHI.Symbols.JACKPOT and item3 == REDSUSHI.Symbols.JACKPOT then
						REDSUSHI.CONFIG.AddMoney(ply, isWin.pay * (REDSUSHI.CONFIG.CreditValue * self:GetBetAmount()))
						self:TriggerJackpot()
					else
						if self:GetWinAmount() > REDSUSHI.CONFIG.SubJackpotValue then
							self:TriggerJackpot()
						else
							--Check to see if we should trigger redscreen
							if math.random(0.000001, 99.99999999999) <= REDSUSHI.CONFIG.RedscreenChance then
								self:SetWinAmount(isWin.pay * self:GetBetAmount())
								self:TriggerRedscreen(isWin.pay * self:GetBetAmount())
							else
								self:TriggerWinscreen(isWin.pay * self:GetBetAmount())
							end
						end
					end

					
					REDSUSHI.CONFIG.AddMoney(ply, isWin.pay * (REDSUSHI.CONFIG.CreditValue * self:GetBetAmount()))
					ply:ChatPrint("[SLOT] You won $"..(isWin.pay * REDSUSHI.CONFIG.CreditValue * self:GetBetAmount()).."!")
				else
					self:EmitSound("redsushi/stop3.mp3")
					self.isSpinning = false	
				end


			end)	
		end)	
	end)
end

function ENT:Think()
	if self.spinner ~= nil and self.isSpinning == false and IsValid(self.spinner) then
		if CurTime() - self.spinnerUpdate > REDSUSHI.CONFIG.ClaimTime then
			self.spinner.redsushimachine = nil
			self.spinner = nil
		end
	else
		if self.spinner ~= nil and IsValid(self.spinner) == false then
			self.spinner = nil
		end
	end
end

function ENT:Use(act, ply)

	//This is a hidden feature (one that was removed)
	//If you uncomment below then it will allow admins to do CTRL+E to
	//edit the chances for that single machine
	//This was removed as I don't think its needed but you can reenable it here

	//if ply:KeyDown(IN_DUCK) then
	//	if table.HasValue(REDSUSHI.CONFIG.AuthorisedRanks, ply:GetUserGroup()) then
	//		
	//		net.Start("REDSUSHI_EDIT_CHANCES")
	//		net.WriteEntity(self)
	//		net.WriteTable(self.chances)
	//		net.Send(ply)
	//
	//		return
	//	end
	//end

	--Do a bunch of auth and shit to make sure they can use the machine first
	if not self.isSpinning and self.spinner ~= nil then
		if self.spinner ~= ply then
			ply:ChatPrint("[SLOT] You must wait for "..self.spinner:Name().." to finish their turn first.")
			return
		end

		if ply:KeyDown(IN_SPEED) then
			local betAmount = self:GetBetAmount()
			betAmount = betAmount + 1

			if betAmount > 3 then
				betAmount = 1
			end

			ply:ChatPrint("[SLOT] You haved changed the bet to '"..betAmount.." CR'")

			self:SetBetAmount(betAmount)
		else
			self:StartSpin(ply)
		end
	else
		if self.spinner == nil and not self.isSpinning then
			if ply.redsushimachine == nil then
				self:StartSpin(ply)
			else
				if not self.isSpinning then
					ply:ChatPrint("[SLOT] Please wait up to 30 seconds before switching machines (Red Sushi)")
				end

				return 
			end

		end
	end
end

net.Receive("REDSUSHI_EDIT_CHANCES", function(len, ply)
	local e = net.ReadEntity()
	local chances = net.ReadTable()

	if table.HasValue(REDSUSHI.CONFIG.AuthorisedRanks, ply:GetUserGroup()) then
		e.chances = chances
		e.customChances = true

		ply:ChatPrint("[SLOT] Chances have been updated, remember to do !saveslots to save the changes!")

	end
end)