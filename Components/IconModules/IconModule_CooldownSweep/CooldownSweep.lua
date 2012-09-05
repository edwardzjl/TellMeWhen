-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local OnGCD = TMW.OnGCD

local CooldownSweep = TMW:NewClass("IconModule_CooldownSweep", "IconModule")

CooldownSweep:RegisterIconDefaults{
	ShowTimer = false,
	ShowTimerText = false,
	ClockGCD = false,
}

CooldownSweep:RegisterConfigPanel_ConstructorFunc(200, "TellMeWhen_TimerSettings", function(self)
	self.Header:SetText(L["CONFIGPANEL_TIMER_HEADER"])
	TMW.IE:BuildSimpleCheckSettingFrame(self, {
		numPerRow = 2,
		{
			setting = "ShowTimer",
			title = TMW.L["ICONMENU_SHOWTIMER"],
			tooltip = TMW.L["ICONMENU_SHOWTIMER_DESC"],
		},
		{
			setting = "ShowTimerText",
			title = TMW.L["ICONMENU_SHOWTIMERTEXT"],
			tooltip = TMW.L["ICONMENU_SHOWTIMERTEXT_DESC"],
			--[[disabled = function()
				return not (IsAddOnLoaded("OmniCC") or IsAddOnLoaded("tullaCC") or LibStub("AceAddon-3.0"):GetAddon("LUI_Cooldown", true))
			end,]]
		},
		{
			setting = "ClockGCD",
			title = TMW.L["ICONMENU_CLOCKGCD"],
			tooltip = TMW.L["ICONMENU_CLOCKGCD_DESC"],
			disabled = function(self)
				return not TMW.CI.ics.ShowTimer and not TMW.CI.ics.ShowTimerText
			end,
		},
	})
end)


TMW:RegisterUpgrade(60315, {
	icon = function(self, ics)
		-- Pull the setting from the profile settings, since this setting is now per-icon
		-- Also, the setting changed from "Ignore" to "Allow", so flip the boolean too.
		
		-- Old default value was true, so make sure we use true if the setting is nil from having been the same as default.
		local old = TMW.db.global.ClockGCD
		if old == nil then
			old = true
		end
		
		ics.ClockGCD = not old
	end,
})

TMW:RegisterUpgrade(45608, {
	icon = function(self, ics)
		if not ics.ShowTimer then
			ics.ShowTimerText = false
		end
	end,
})

TMW:RegisterCallback("TMW_DB_PRE_DEFAULT_UPGRADES", function()
	-- The default for ShowTimerText changed from true to false in v45607
	-- So, if the user is upgrading to this version, and ShowTimerText is nil,
	-- then it must have previously been set to true, causing Ace3DB not to store it,
	-- so explicity set it as true to make sure it doesn't change just because the default changed.
	
	if TellMeWhenDB.profiles and TellMeWhenDB.Version < 45607 then
		for _, p in pairs(TellMeWhenDB.profiles) do
			if p.Groups then
				for _, gs in pairs(p.Groups) do
					if gs.Icons then
						for _, ics in pairs(gs.Icons) do
							if ics.ShowTimerText == nil then
								ics.ShowTimerText = true
							end
						end
					end
				end
			end
		end
	end
end)

CooldownSweep:RegisterAnchorableFrame("Cooldown")

function CooldownSweep:OnNewInstance(icon)
	self.cooldown = CreateFrame("Cooldown", self:GetChildNameBase() .. "Cooldown", icon, "CooldownFrameTemplate")
	
	self:SetSkinnableComponent("Cooldown", self.cooldown)
end

function CooldownSweep:OnDisable()
	local cd = self.cooldown
	
	cd.start, cd.duration = 0, 0
	cd.charges, cd.maxCharges = nil, nil
	
	self:UpdateCooldown()
end

function CooldownSweep:SetupForIcon(icon)
	self.ShowTimer = icon.ShowTimer
	self.ShowTimerText = icon.ShowTimerText
	self.ClockGCD = icon.ClockGCD
	self.cooldown.noCooldownCount = not icon.ShowTimerText
	
	local attributes = icon.attributes
	
	if not TMW.ISMOP then
		-- SetDrawEdge has been removed in MOP
		self.cooldown:SetDrawEdge(TMW.db.profile.DrawEdge)
	end	
	
	self:DURATION(icon, attributes.start, attributes.duration)
	self:SPELLCHARGES(icon, attributes.charges, attributes.maxCharges)
	self:REVERSE(icon, attributes.reverse)
end

function CooldownSweep:UpdateCooldown()
	local cd = self.cooldown
	local duration = cd.duration
	
	cd:SetCooldown(cd.start, duration, cd.charges, cd.maxCharges)
	
	if duration > 0 then
		cd:Show()
		cd:SetAlpha(self.ShowTimer and 1 or 0)
	else
		cd:Hide()
	end

	if not self.ShowTimer then
		cd:SetAlpha(0)
	end
end

function CooldownSweep:DURATION(icon, start, duration)
	local cd = self.cooldown
	
	if (not self.ClockGCD and OnGCD(duration)) or (duration - (TMW.time - start)) <= 0 or duration <= 0 then
		start, duration = 0, 0
	end
	
	if cd.start ~= start or cd.duration ~= duration then
		cd.start = start
		cd.duration = duration
		
		self:UpdateCooldown()
	end
end
CooldownSweep:SetDataListner("DURATION")

function CooldownSweep:SPELLCHARGES(icon, charges, maxCharges)
	local cd = self.cooldown
	
	if cd.charges ~= charges or cd.maxCharges ~= maxCharges then
		cd.charges = charges
		cd.maxCharges = maxCharges
		
		self:UpdateCooldown()
	end
end
CooldownSweep:SetDataListner("SPELLCHARGES")

function CooldownSweep:REVERSE(icon, reverse)
	self.cooldown:SetReverse(reverse)
end
CooldownSweep:SetDataListner("REVERSE")

	