REDSUSHI =  {}

REDSUSHI.Symbols = {
	JACKPOT = 0,
	CHERRY = 1,
	SEVEN = 2,
	BAR = 3,
	BARBAR = 4,
	BARBARBAR = 5,
	VOID = 6
}

--Local copy of symbols for easier access
local Symbols = REDSUSHI.Symbols

--Index this table by the symbol enum and it will return
--the index position on the reel (will always return a table of them)
REDSUSHI.SymbolsToReelPosition = {
	[Symbols.JACKPOT] = {0},
	[Symbols.CHERRY] = {2, 8},
	[Symbols.SEVEN] = {12},
	[Symbols.BAR] = {4, 14},
	[Symbols.BARBAR] = {10},
	[Symbols.BARBARBAR] = {6},
	[Symbols.VOID] = {1, 3, 5, 7, 9, 11, 13, 15}
}

--Include the config now that the symbols are loaded
include("config_redsushi.lua")
AddCSLuaFile("config_redsushi.lua")

--Save all the slots loaded on the map
function REDSUSHI.SaveSlots()
	local data = {}

	for k, v in pairs(ents.FindByClass("redsushi_slot")) do
		if v.customChances then
			table.insert(data, {
				custom = true,
				chances = v.chances,
				pos = v:GetPos(),
				ang = v:GetAngles()
			})
		else
			table.insert(data, {
				pos = v:GetPos(),
				ang = v:GetAngles()
			})		
		end
	end

	data = util.TableToJSON(data)

	file.Write("redsushi_"..game.GetMap()..".txt", data)
end

--Loads the slots and spawns them
function REDSUSHI.LoadSlots()
	local data = file.Read("redsushi_"..game.GetMap()..".txt")

	if data ~= nil then
		local data = util.JSONToTable(data)

		for k, v in pairs(data) do
			local e = ents.Create("redsushi_slot")
			e:SetPos(v.pos)
			e:SetAngles(v.ang)
			e:Spawn()
			e:GetPhysicsObject():EnableMotion(false)

			if e.custom then
				e.chances = data.chances
			end	
		end
	end
end


hook.Add( "InitPostEntity", "REDSUSHI:LoadSlots", function()
	REDSUSHI.LoadSlots()
end )

hook.Add("PlayerSay", "REDSUSHI:SaveSlots", function(ply, text)
	if string.sub(text, 1, 10) == "!saveslots" then
		if table.HasValue(REDSUSHI.CONFIG.AuthorisedRanks, ply:GetUserGroup()) then
			--Save the slots
			REDSUSHI.SaveSlots()
			ply:ChatPrint("[SLOT] Redsushi slots haved been saved for this map.")
			return false
		else
			ply:ChatPrint("[SLOT] You don't have permission to do this.")
		end
	end
end) 



--Will return false if its not a win, and a table if it is a win.
function REDSUSHI.IsWin(index1, index2, index3)
	for k, v in pairs(REDSUSHI.WinTable) do
		local match = true
 
		if not table.HasValue(v[1], -1) then 
			if not table.HasValue(v[1], index1) then
				continue 
			end
		end

		if not table.HasValue(v[2], -1) then
			if not table.HasValue(v[2], index2) then
				continue
			end
		end

		if not table.HasValue(v[3], -1) then
			if not table.HasValue(v[3], index3) then
				continue
			end
		end

		return v
	end

	return false
end