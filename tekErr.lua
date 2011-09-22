
local LOG_TAINT = true
local MINIMAP_BUTTON = true

----------------------------------------
--      Quicklaunch registration      --
----------------------------------------
local ERR_NUM = 0

local TXT_NO_ERR = '|cff00ff00No err|r'
local TXT_NUM_ERR = '|cffff0000%d errs|r'

local dataobj = LibStub("LibDataBroker-1.1"):NewDataObject("tekErr", {
	type = "data source",
	icon = "Interface\\Icons\\Ability_Creature_Cursed_04",
	text = TXT_NO_ERR,
})

function dataobj.OnClick()
	dataobj.text = TXT_NO_ERR
	ERR_NUM = 0
	SlashCmdList.TEKERR()
end


-----------------------------------------

local linkstr = "|cffff4040[%s] |Htekerr:%s|h%s|h|r"
local taint_linkstr = "|cff00ffff[%s] |Htekerr:%s|h%s|h|r"

local butt
local panel = LibStub("tekPanel-Auction").new("tekErrPanel", "tekErr")
local f = CreateFrame("ScrollingMessageFrame", nil, panel)
f:SetPoint("BOTTOMRIGHT", -15, 40)
f:SetMaxLines(2500)
f:SetFontObject(GameFontHighlightSmall)
f:SetJustifyH("LEFT")
f:SetFading(false)
f:SetScript("OnShow", function() if butt then butt:Hide() end end)
--f:SetScript("OnEvent", function(self, ...) self:AddMessage(string.join(", ", ...), 0.0, 1.0, 1.0) end)
--f:RegisterEvent("ADDON_ACTION_FORBIDDEN")
--~ f:RegisterEvent("ADDON_ACTION_BLOCKED")  -- We usually don't care about these, as they aren't fatal
TheLowDownRegisterFrame(f)
TheLowDownRegisterFrame = nil
butt = MINIMAP_BUTTON and tekErrMinimapButton(f)
tekErrMinimapButton = nil

local function NewErr()
	if panel:IsShown() then
		dataobj.text = TXT_NO_ERR
		ERR_NUM = 0
	else
		ERR_NUM = ERR_NUM + 1
		dataobj.text = TXT_NUM_ERR:format(ERR_NUM)
	end
    if(butt and not butt:IsShown()) then
        butt:Show()
    end
end


if LOG_TAINT then
    for k,v in pairs{   'ADDON_ACTION_BLOCKED',
                        'MACRO_ACTION_BLOCKED',
                        'ADDON_ACTION_FORBIDDEN',
                        'MACRO_ACTION_FORBIDDEN', } do
        f:RegisterEvent(v)
    end
end

f:SetScript("OnEvent", function(self, ...)
	local msg = string.join(", ", ...)
	local text = string.format(taint_linkstr, date("%X"), debugstack(2), msg)
	self:AddMessage(text)
	NewErr()
end)


seterrorhandler(function(msg)
	local _, _, stacktrace = string.find(debugstack(1, 50, 50) or "", "[^\n]+\n(.*)")
	f:AddMessage(string.format(linkstr, date("%X"), stacktrace, msg))
	NewErr()
end)


panel:SetScript("OnShow", function(self)
	local editbox = CreateFrame("EditBox", nil, panel)
	editbox:SetPoint("TOPLEFT", 25, -75)
	editbox:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", -15, -100)
	editbox:SetFontObject(GameFontHighlightSmall)
	editbox:SetTextInsets(8,8,8,8)
	editbox:SetBackdrop{
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	}
	editbox:SetBackdropColor(.1,.1,.1,1)
	editbox:SetMultiLine(true)
	editbox:SetAutoFocus(false)
	editbox:SetScript("OnTextSet", function(self)
		if self:GetText() == "" then
			editbox:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", -15, -100)
		else
			editbox:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", -15, -325)
			editbox:SetFocus()
			editbox:HighlightText()
		end
	end)
	editbox:SetScript("OnEscapePressed", editbox.ClearFocus)
	editbox:SetScript("OnEditFocusLost", function(editbox) editbox:SetText("") end)

	f:SetPoint("TOPLEFT", editbox, "BOTTOMLEFT")
	f:EnableMouseWheel(true)
	f:SetScript("OnHide", f.ScrollToBottom)
	f:SetScript("OnHyperlinkClick", function(frame, link, text)
		local _, _, msg = string.find(link, "tekerr:(.+)")
		editbox:SetText(text.. "\n".. msg)
	end)
	f:SetScript("OnMouseWheel", function(frame, delta)
		if delta > 0 then
			if IsShiftKeyDown() then frame:ScrollToTop()
			elseif IsControlKeyDown() then for i =1,10 do frame:ScrollUp() end
			else frame:ScrollUp() end
		elseif delta < 0 then
			if IsShiftKeyDown() then frame:ScrollToBottom()
			elseif IsControlKeyDown() then for i =1,10 do frame:ScrollDown() end
			else frame:ScrollDown() end
		end
	end)

	self:SetScript("OnShow", nil)
end)


-----------------------------
--      Slash Handler      --
-----------------------------

SLASH_TEKERR1 = "/err"
SLASH_TEKERR2 = "/tekerr"
function SlashCmdList.TEKERR()
	if panel:IsShown() then HideUIPanel(panel)
	else ShowUIPanel(panel) end
end

SLASH_TEKRELOADUI = '/rl'
function SlashCmdList.TEKRELOADUI()
    ReloadUI()
end
