local _G = _G
local _, RE = ...
_G.RETabBinder = RE

local print, pairs = _G.print, _G.pairs
local InCombatLockdown = _G.InCombatLockdown
local IsInInstance = _G.IsInInstance
local GetCurrentBindingSet = _G.GetCurrentBindingSet
local GetZonePVPInfo = _G.GetZonePVPInfo
local GetBindingKey = _G.GetBindingKey
local GetBindingAction = _G.GetBindingAction
local SetBinding = _G.SetBinding
local SaveBindings = _G.SaveBindings

RE.AceConfig = {
	type = "group",
	args = {
		DefaultKey = {
			name = "Use default bindings",
			desc = "Disable to use bindings other than TAB/Shift-TAB.",
			type = "toggle",
			width = "full",
			order = 1,
			set = function(_, val) RE.Settings.DefaultKey = val; RE:OnEvent(nil, "ZONE_CHANGED_NEW_AREA") end,
			get = function(_) return RE.Settings.DefaultKey end
		},
		OpenWorld = {
			name = "Consider normal zones as PvP ones",
			desc = "Enable to consider normal open world zones as PvP instances.",
			type = "toggle",
			width = "full",
			order = 2,
			set = function(_, val) RE.Settings.OpenWorld = val; RE:OnEvent(nil, "ZONE_CHANGED_NEW_AREA") end,
			get = function(_) return RE.Settings.OpenWorld end
		},
		SilentMode = {
			name = "Disable chat messages",
			desc = "Disable printing status messages to the chat window.",
			type = "toggle",
			width = "full",
			order = 3,
			set = function(_, val) RE.Settings.SilentMode = val end,
			get = function(_) return RE.Settings.SilentMode end
		}
	}
}
RE.DefaultConfig = {
	DefaultKey = true,
	OpenWorld = false,
	SilentMode = false
}
RE.Fail = false

function RE:OnLoad(self)
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("DUEL_REQUESTED")
	self:RegisterEvent("DUEL_FINISHED")
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	self:RegisterEvent("ADDON_LOADED")
end

function RE:OnEvent(self, event, ...)
	if event == "ADDON_LOADED" and ... == "RETabBinder" then
		if not _G.RETabBinderSettings then
			_G.RETabBinderSettings = RE.DefaultConfig
		end
		RE.Settings = _G.RETabBinderSettings
		for key, value in pairs(RE.DefaultConfig) do
			if RE.Settings[key] == nil then
				RE.Settings[key] = value
			end
		end
		_G.LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("RETabBinder", RE.AceConfig)
		_G.LibStub("AceConfigDialog-3.0"):AddToBlizOptions("RETabBinder", "RETabBinder")
		--RE:OnEvent(self, "ZONE_CHANGED_NEW_AREA")
		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "ZONE_CHANGED_NEW_AREA" or (event == "PLAYER_REGEN_ENABLED" and RE.Fail) or event == "DUEL_REQUESTED" or event == "DUEL_FINISHED" or event == "CHAT_MSG_SYSTEM" then
		if event == "CHAT_MSG_SYSTEM" and ... == _G.ERR_DUEL_REQUESTED then
			event = "DUEL_REQUESTED"
		elseif event == "CHAT_MSG_SYSTEM" then
			return
		end

		local BindSet = GetCurrentBindingSet()
		if BindSet ~= 1 and BindSet ~= 2 then
			return
		end
		if InCombatLockdown() then
			RE.Fail = true
			return
		end
		local PVPType = GetZonePVPInfo()
		local _, ZoneType = IsInInstance()

		local TargetKey = GetBindingKey("TARGETNEARESTENEMYPLAYER")
		if TargetKey == nil then
			TargetKey = GetBindingKey("TARGETNEARESTENEMY")
		end
		if TargetKey == nil and RE.Settings.DefaultKey then
			TargetKey = "TAB"
		end

		local LastTargetKey = GetBindingKey("TARGETPREVIOUSENEMYPLAYER")
		if LastTargetKey == nil then
			LastTargetKey = GetBindingKey("TARGETPREVIOUSENEMY")
		end
		if LastTargetKey == nil and RE.Settings.DefaultKey then
			LastTargetKey = "SHIFT-TAB"
		end

		local CurrentBind
		if TargetKey then
			CurrentBind = GetBindingAction(TargetKey)
		end

		if ZoneType == "arena" or ZoneType == "pvp" or (RE.Settings.OpenWorld and ZoneType == "none") or PVPType == "combat" or event == "DUEL_REQUESTED" then
			if CurrentBind ~= "TARGETNEARESTENEMYPLAYER" then
				local Success
				if TargetKey == nil then
					Success = true
				else
					Success = SetBinding(TargetKey, "TARGETNEARESTENEMYPLAYER")
				end
				if LastTargetKey then
					SetBinding(LastTargetKey, "TARGETPREVIOUSENEMYPLAYER")
				end
				if Success then
					SaveBindings(BindSet)
					RE.Fail = false
					if not RE.Settings.SilentMode then
						C_CVar.SetCVar("nameplateMaxDistance", 41)
						print("\124cFF74D06C[RETabBinder]\124r PVP Mode")
					end
				else
					RE.Fail = true
				end
			end
		else
			if CurrentBind ~= "TARGETNEARESTENEMY" then
				local Success
				if TargetKey == nil then
					Success = true
				else
					Success = SetBinding(TargetKey, "TARGETNEARESTENEMY")
				end
				if LastTargetKey then
					SetBinding(LastTargetKey, "TARGETPREVIOUSENEMY")
				end
				if Success then
					SaveBindings(BindSet)
					RE.Fail = false
					if not RE.Settings.SilentMode then
						C_CVar.SetCVar("nameplateMaxDistance", 20)
						print("\124cFF74D06C[RETabBinder]\124r PVE Mode")
					end
				else
					RE.Fail = true
				end
			end
		end
	end
end
