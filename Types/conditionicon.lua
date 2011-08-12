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

local db, UPD_INTV
local print = TMW.print




local Type = {}
Type.name = L["ICONMENU_CNDTIC"]
Type.desc = L["ICONMENU_CNDTIC_DESC"]
Type.WhenChecks = {
	text = L["ICONMENU_CNDTSHOWWHEN"],
	{ value = "alpha",			text = L["ICONMENU_SUCCEED"],			colorCode = "|cFF00FF00" },
	{ value = "unalpha",		text = L["ICONMENU_FAIL"],				colorCode = "|cFFFF0000" },
	{ value = "always",			text = L["ICONMENU_ALWAYS"] },
}
Type.RelevantSettings = {
	CustomTex = false,
	--ConditionAlpha = false,
	ConditionDur = true,
	ConditionDurEnabled = true,
	UnConditionDur = true,
	UnConditionDurEnabled = true,
	ShowCBar = true,
	CBarOffs = true,
	InvertBars = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
}

function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
end

local function ConditionIcon_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck
		if CndtCheck then
			local shouldReturn, succeeded = CndtCheck() -- we dont use shouldreturn.
			icon.CndtFailed = nil -- you are a pirate (actually, you hack your own code, but close enough)
			local alpha = succeeded and icon.Alpha or icon.UnAlpha
			
			if succeeded and not icon.__succeeded and icon.ConditionDurEnabled then
				icon:SetInfo(alpha, 1, nil, time, icon.ConditionDur)
			elseif not succeeded and icon.__succeeded and icon.UnConditionDurEnabled  then
				icon:SetInfo(alpha, 1, nil, time, icon.UnConditionDur)
			else
				icon:SetInfo(alpha, 1, nil, icon.__start, icon.__duration)
			end
			
			icon.__succeeded = succeeded
		else
			icon:SetAlpha(1)
		end
	end
end


Type.AllowNoName = true
function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	--icon.ConditionAlpha = icon.UnAlpha
	
	local tex, reason = TMW:GetConfigIconTexture(icon)
	icon:SetTexture(tex)
	if reason == false then
		icon:SetTexture(icon.Name)
		if not icon.texture:GetTexture() then
			icon:SetTexture("Interface\\Icons\\" .. icon.Name)
		end
		if not icon.texture:GetTexture() then
			icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end
	end
	icon.__start = icon.__start or 0 --TellMeWhen-4.2.1.2.lua:2115 attempt to perform arithmetic on local "start" (a nil value) -- caused because condition icons do necessarily define start/durations, even if shown.
	icon.__duration = icon.__duration or 0
	icon.__vrtxcolor = 1
	
	icon:SetScript("OnUpdate", ConditionIcon_OnUpdate)
	--icon:OnUpdate(TMW.time) -- dont do this!
end

function Type:IE_TypeLoaded()
	local Name = TMW.IE.Main.Name
	Name.label = L["ICONMENU_CHOOSENAME_CNDTIC"]
	Name.__title = L["ICONMENU_CHOOSENAME_CNDTIC"]
	Name.__text = L["CHOOSENAME_DIALOG_CNDTIC"]
	Name:GetScript("OnTextChanged")(Name)
	
	TMW.IE.Main.ConditionAlpha.text:SetText(L["CONDITIONALPHA_CONDITIONICON"])
	TMW:TT(TMW.IE.Main.ConditionAlpha, "CONDITIONALPHA_CONDITIONICON", "CONDITIONALPHA_CONDITIONICON_DESC")
end

function Type:IE_TypeUnloaded()
	local Name = TMW.IE.Main.Name
	Name.label = L["ICONMENU_CHOOSENAME"]
	Name.__title = L["ICONMENU_CHOOSENAME"]
	Name.__text = L["CHOOSENAME_DIALOG"]
	Name:GetScript("OnTextChanged")(Name)
	
	TMW.IE.Main.ConditionAlpha.text:SetText(L["CONDITIONALPHA"])
	TMW:TT(TMW.IE.Main.ConditionAlpha, "CONDITIONALPHA", "CONDITIONALPHA_DESC")
end

TMW:RegisterIconType(Type, "conditionicon")
