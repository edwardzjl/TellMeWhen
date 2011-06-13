﻿-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local db, UPD_INTV, pr, ab
local strlower =
	  strlower
local GetSpellTexture =
	  GetSpellTexture
local print = TMW.print
local SpellTextures = TMW.SpellTextures

local pGUID = UnitGUID("player") -- this isnt actually defined right here (it returns nil), so I will do it later too
local clientVersion = select(4, GetBuildInfo())
local strlowerCache = TMW.strlowerCache


local Type = TMW:RegisterIconType("icd")
Type.name = L["ICONMENU_ICD"]
Type.desc = L["ICONMENU_ICD_DESC"]
Type.DurationSyntax = 1
Type.TypeChecks = {
	setting = "ICDType",
	text = L["ICONMENU_ICDTYPE"],
	{ value = "aura", 			text = L["ICONMENU_ICDBDE"], 				tooltipText = L["ICONMENU_ICDAURA_DESC"]},
	{ value = "spellcast", 		text = L["ICONMENU_SPELLCAST_COMPLETE"], 	tooltipText = L["ICONMENU_SPELLCAST_COMPLETE_DESC"]},
	{ value = "caststart", 		text = L["ICONMENU_SPELLCAST_START"], 		tooltipText = L["ICONMENU_SPELLCAST_START_DESC"]},
}
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 			text = L["ICONMENU_USABLE"], 			colorCode = "|cFF00FF00" },
	{ value = "unalpha",  		text = L["ICONMENU_UNUSABLE"], 			colorCode = "|cFFFF0000" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}
Type.RelevantSettings = {
	Name = true,
	ShowTimer = true,
	ShowTimerText = true,
	ICDType = true,
	DontRefresh = true,
	ShowWhen = true,
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
	FakeHidden = true,
}


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
	pGUID = UnitGUID("player")
end


local function ICD_OnEvent(icon, event, ...)
	local valid, i, n, _
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local p, g
		if clientVersion >= 40200 then
			_, p, _, g, _, _, _, _, _, _, _, i, n = ...
		elseif clientVersion >= 40100 then
			_, p, _, g, _, _, _, _, _, i, n = ...
		else
			_, p, g, _, _, _, _, _, i, n = ...
		end
		valid = g == pGUID and (p == "SPELL_AURA_APPLIED" or p == "SPELL_AURA_REFRESH" or p == "SPELL_ENERGIZE" or p == "SPELL_AURA_APPLIED_DOSE")
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_START" then
		valid, n, _, _, i = ... -- i cheat. valid is actually a unitID here.
		valid = valid == "player"
	end
	
	if valid then
		local NameDictionary = icon.NameDictionary
		local Key = NameDictionary[i] or NameDictionary[strlowerCache[n]]
		if Key and not (icon.DontRefresh and (TMW.time - icon.ICDStartTime) < icon.Durations[Key]) then
			local t = SpellTextures[i]
			if t ~= icon.__tex then icon:SetTexture(t) end

			icon.ICDStartTime = TMW.time
			icon.ICDDuration = icon.Durations[Key]
		end
	end
end

local function ICD_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end

		local ICDStartTime = icon.ICDStartTime
		local timesince = time - ICDStartTime
		local ICDDuration = icon.ICDDuration

		local d = ICDDuration - timesince
		if (icon.DurationMinEnabled and icon.DurationMin > d) or (icon.DurationMaxEnabled and d > icon.DurationMax) then
			icon:SetAlpha(0)
			return
		end

		if timesince > ICDDuration then
			icon:SetInfo(icon.Alpha, 1, nil, 0, 0)
		else
			icon:SetInfo(icon.UnAlpha, icon.Alpha ~= 0 and (icon.ShowTimer and 1 or .5) or 1, nil, ICDStartTime, ICDDuration)
		end
	end
end

function Type:Setup(icon, groupID, iconID)
	icon.ShowPBar = false
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameDictionary = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.Durations = TMW:GetSpellDurations(icon, icon.Name)

	icon.StartTime = icon.ICDDuration

	--[[ keep these events per icon isntead of global like unitcooldowns are so that ...
	well i had a reason here but it didnt make sense when i came back and read it a while later. Just do it. I guess.]]
	if icon.ICDType == "spellcast" then
		icon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	elseif icon.ICDType == "caststart" then
		icon:RegisterEvent("UNIT_SPELLCAST_START")
		icon:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	elseif icon.ICDType == "aura" then
		icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
	icon:SetScript("OnEvent", ICD_OnEvent)

	if icon.Name == "" then
		icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	elseif SpellTextures[icon.NameFirst] then
		icon:SetTexture(SpellTextures[icon.NameFirst])
	elseif TMW:DoSetTexture(icon) then
		icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
	end

	icon:SetScript("OnUpdate", ICD_OnUpdate)
	icon:OnUpdate(TMW.time)
end


function Type:IE_TypeLoaded()
	if not db.global.SeenNewDurSyntax then
		TMW.IE:ShowHelp(L["HELP_FIRSTUCD"]:format(GetSpellInfo(65547), GetSpellInfo(47528), GetSpellInfo(2139), GetSpellInfo(62618), GetSpellInfo(62618)) 
		, TMW.IE.Main.Type, 20, 0)
		db.global.SeenNewDurSyntax = 1
	end
end

function Type:IE_TypeUnloaded()
	if TMW.CI.t ~= "unitcooldown" and TMW.CI.t ~= "icd" then
		TMW.IE.Help:Hide()
	end
end

