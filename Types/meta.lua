﻿-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>
-- Major updates by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local db, CUR_TIME, UPD_INTV
local _G, strmatch, tonumber, ipairs =
	  _G, strmatch, tonumber, ipairs
local AlreadyChecked = {} TMW.AlreadyChecked = AlreadyChecked

local RelevantSettings = {
	Icons = true,
	CheckNext = true,
}

local Type = TMW:RegisterIconType("meta", RelevantSettings)
Type.name = L["ICONMENU_META"]
Type.desc = L["ICONMENU_META_DESC"]

Type:SetScript("OnUpdate", function()
	CUR_TIME = TMW.CUR_TIME
end)

function Type:Update()
	CUR_TIME = TMW.CUR_TIME
	db = TMW.db
	UPD_INTV = db.profile.Interval
end

local function Meta_OnUpdate(icon)
	if icon.UpdateTimer <= CUR_TIME - UPD_INTV then
		icon.UpdateTimer = CUR_TIME
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end
		local CheckNext = icon.CheckNext
		for k, i in ipairs(icon.Icons) do
			local ic = _G[i]
			if ic and ic.OnUpdate and (not CheckNext or (CheckNext and not AlreadyChecked[ic])) then
				ic:OnUpdate()
				local alpha = ic.FakeAlpha
				if alpha > 0 and ic.__shown and ic.group.__shown then
				
					icon.cooldown.noCooldownCount = ic.cooldown.noCooldownCount
					icon:SetCooldown(ic.__start, ic.__duration, ic.__reverse)

					icon:SetTexture(ic.__tex)
					icon:SetVertexColor(ic.__vrtxinfo)
					icon:SetAlpha(alpha)

					icon:SetStack(ic.__count)
					icon.InvertBars = ic.InvertBars

					local icpb = ic.powerbar
					if ic.ShowPBar and icpb.UpdateSet then
						icon:PwrBarStart(icpb.name)
						icon.powerbar:SetStatusBarColor(icpb:GetStatusBarColor())
					else
						icon.powerbar.Max = icpb.Max
						icon:PwrBarStop(1)
					end

					local iccb = ic.cooldownbar
					if ic.ShowCBar and iccb.UpdateSet then
						icon:CDBarStart(iccb.start, iccb.duration)
					else
						icon.cooldownbar.Max = iccb.Max
						icon:CDBarStop(1)
					end
					AlreadyChecked[ic] = true
					return
				end
			end
		end
		icon:SetAlpha(0)
	end
end

local function GetFullIconTable(icons, tbl) -- for meta icons, to check what all the possible icons it can show are
	tbl = tbl or {}
	for i, ic in ipairs(icons) do
		local g, i = strmatch(ic, "TellMeWhen_Group(%d+)_Icon(%d+)")
		g, i = tonumber(g), tonumber(i)
		if db.profile.Groups[g].Icons[i].Type ~= "meta" then
			tinsert(tbl, ic)
		else
			GetFullIconTable(db.profile.Groups[g].Icons[i].Icons, tbl)
		end
	end
	return tbl
end

Type.AllowNoName = true
function Type:Setup(icon, groupID, iconID)
	icon.NameFirst = "" --need to set this to something for bars update
	icon.ProcessedAt = 1
	if icon.CheckNext then
		TMW.DoWipeAC = true
		icon.Icons = GetFullIconTable(icon.Icons)
	end
	icon.ShowPBar = true
	icon.ShowCBar = true
	icon.InvertBars = false
	icon:SetTexture("Interface\\Icons\\LevelUpIcon-LFD")

	icon:SetScript("OnUpdate", Meta_OnUpdate)
end

