﻿-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by
-- Sweetmms of Blackrock
-- Oozebull of Twisting Nether
-- Oodyboo of Mug'thol
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local _, pclass = UnitClass("Player")

local db, UPD_INTV, ClockGCD, pr, ab, rc, mc
local strlower =
	  strlower
local GetTotemInfo, GetSpellTexture =
	  GetTotemInfo, GetSpellTexture
local print = TMW.print
local strlowerCache = TMW.strlowerCache


local Type = TMW:RegisterIconType("totem")
Type.name = pclass == "DRUID" and L["ICONMENU_MUSHROOMS"] or pclass == "DEATHKNIGHT" and L["ICONMENU_GHOUL"] or L["ICONMENU_TOTEM"]
Type.usePocketWatch = 1
if pclass == "SHAMAN" then
	Type.TypeChecks = {
		setting = "TotemSlots",
		text = L["TOTEMS"],
		{ text = L["FIRE"] },
		{ text = L["EARTH"] },
		{ text = L["WATER"] },
		{ text = L["AIR"] },
	}
elseif pclass == "DRUID" then
	Type.TypeChecks = {
		setting = "TotemSlots",
		text = L["MUSHROOMS"],
		{ text = format(L["MUSHROOM"], 1) },
		{ text = format(L["MUSHROOM"], 2) },
		{ text = format(L["MUSHROOM"], 3) },
	}
end
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 			text = L["ICONMENU_PRESENT"], 			colorCode = "|cFF00FF00" },
	{ value = "unalpha", 		text = L["ICONMENU_ABSENT"], 			colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}
Type.RelevantSettings = {
	Name = pclass ~= "DRUID" and pclass ~= "DEATHKNIGHT",
	CustomTex = true,
	ShowTimer = true,
	ShowTimerText = true,
	ShowWhen = true,
	ShowPBar = true,
	PBarOffs = true,
	ShowCBar = true,
	CBarOffs = true,
	InvertBars = true,
	Alpha = true,
	UnAlpha = true,
	ConditionAlpha = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
	TotemSlots = true,
	FakeHidden = true,
}


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
	ClockGCD = db.profile.ClockGCD
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
end

local function Totem_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local Slots, NameNameDictionary, NameFirst = icon.Slots, icon.NameNameDictionary, icon.NameFirst
		for iSlot = 1, #Slots do -- be careful here. slots that are explicitly disabled by the user are set false. slots that are disabled internally are set nil.
			if Slots[iSlot] then
				local _, totemName, start, duration, totemIcon = GetTotemInfo(iSlot)
				if start ~= 0 and totemName and ((NameFirst == "") or NameNameDictionary[strlowerCache[totemName]]) then
					icon:SetInfo(icon.Alpha, icon.UnAlpha ~= 0 and pr or 1, totemIcon, start, duration, nil, totemName)
					return
				end
			end
		end
		icon:SetInfo(icon.UnAlpha, icon.Alpha ~= 0 and ab or 1, icon.FirstTexture, 0, 0)
	end
end


Type.AllowNoName = true
function Type:Setup(icon, groupID, iconID)
	if icon.Name then
		icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
		icon.NameName = TMW:GetSpellNames(icon, icon.Name, 1, 1)
		icon.NameNameDictionary = TMW:GetSpellNames(icon, icon.Name, nil, 1, 1)
	end
	icon.Slots = wipe(icon.Slots or {})
	for i=1, 4 do
		icon.Slots[i] = tonumber(strsub(icon.TotemSlots.."0000", i, i)) == 1
	end
	if pclass == "DEATHKNIGHT" then
		icon.NameFirst = ""
		icon.NameName = GetSpellInfo(46584)
		icon.Slots[1] = true -- there is only one slot for DKs, and they dont have options to check certain slots
		icon.Slots[2] = nil
		icon.Slots[3] = nil
		icon.Slots[4] = nil
	elseif pclass == "DRUID" then
		icon.NameFirst = ""
		icon.NameName = GetSpellInfo(88747)
		icon.Slots[4] = nil -- there is no mushroom 4
	elseif pclass ~= "SHAMAN" then --enable all totems for people that dont have totem slot options (future-proof it)
		icon.Slots[1] = true
		icon.Slots[2] = true
		icon.Slots[3] = true
		icon.Slots[4] = true
	end
	icon:SetReverse(true)

	icon.FirstTexture = icon.NameName and TMW.SpellTextures[icon.NameName]

	if pclass == "DRUID" then
		icon:SetTexture(GetSpellTexture(88747))
	elseif pclass == "DEATHKNIGHT" then
		icon:SetTexture(GetSpellTexture(46584))
	else
		icon:SetTexture(TMW:GetConfigIconTexture(icon))
	end

	icon:SetScript("OnUpdate", Totem_OnUpdate)
	icon:OnUpdate(TMW.time)
end


