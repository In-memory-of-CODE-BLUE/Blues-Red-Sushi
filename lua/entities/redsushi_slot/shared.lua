ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "RedSushi Slot"
ENT.Author = "<CODE BLUE>"
ENT.Contact = "Via Steam"
ENT.Spawnable = true
ENT.Category = "Blue's Slots"
ENT.AdminSpawnable = true 

--Vars for the screen
function ENT:SetupDataTables()
	self:NetworkVar("Bool",0, "IsRedScreen")
	self:NetworkVar("Bool",1, "IsJackpotScreen")
	self:NetworkVar("Int",0, "WinAmount")
	self:NetworkVar("Int",1, "BetAmount")
	self:NetworkVar("Int",2, "CreditAmount") --The number of credits of there balance/credit amount (floored)
end