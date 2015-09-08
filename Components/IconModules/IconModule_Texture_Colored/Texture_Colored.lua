﻿-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local type = type
local bitband = bit.band

local OnGCD = TMW.OnGCD

local ColorGCD, ColorMSQ, OnlyMSQ

local Texture_Colored = TMW:NewClass("IconModule_Texture_Colored", "IconModule_Texture")

function Texture_Colored:SetupForIcon(icon)
	self.Colors = icon.typeData.Colors
	self.ShowTimer = icon.ShowTimer
	self:UPDATE(icon)
end

local COLOR_UNLOCKED = {
	Color = "ffffffff",
	Gray = false,
}
function Texture_Colored:UPDATE(icon)
	local attributes = icon.attributes
	local duration, inrange, nomana, charges = attributes.duration, attributes.inRange, attributes.noMana, attributes.charges
--[[
	OOR	=	{r=0.5,	g=0.5,	b=0.5	},	-- out of range
	OOM	=	{r=0.5,	g=0.5,	b=0.5	},	-- out of mana
	OORM=	{r=0.5,	g=0.5,	b=0.5	},	-- out of range and mana]]

	local color
	if not TMW.Locked then
		color = COLOR_UNLOCKED
	elseif inrange == false and nomana then
		color = self.Colors.OORM
	elseif inrange == false then
		color = self.Colors.OOR
	elseif nomana then
		color = self.Colors.OOM
	else

		color = COLOR_UNLOCKED
	end
	
	local texture = self.texture
	local r, g, b = TMW:StringToRGB(color.Color)
	
	if not (LMB and OnlyMSQ) then
		texture:SetVertexColor(r, g, b, 1)
	else
		texture:SetVertexColor(1, 1, 1, 1)
	end
	texture:SetDesaturated(color.Gray)
	
	if LMB and ColorMSQ then
		local iconnt = icon.normaltex
		if iconnt then
			iconnt:SetVertexColor(r, g, b, 1)
		end
	end
end

Texture_Colored:SetDataListner("INRANGE", Texture_Colored.UPDATE)
Texture_Colored:SetDataListner("NOMANA", Texture_Colored.UPDATE)
Texture_Colored:SetDataListner("DURATION", Texture_Colored.UPDATE)
Texture_Colored:SetDataListner("SPELLCHARGES", Texture_Colored.UPDATE)


TMW:RegisterCallback("TMW_GLOBAL_UPDATE", function()
	ColorMSQ = TMW.db.profile.ColorMSQ
	OnlyMSQ = TMW.db.profile.OnlyMSQ
	ColorGCD = TMW.db.profile.ColorGCD
end)