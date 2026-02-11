local types = require(script.Parent.Parent.types)
local plugin = script:FindFirstAncestorWhichIsA("Plugin")
local mouseIcons = {
	default = "",
	crosshairs = "rbxasset://SystemCursors/Cross",
	openHand = "rbxasset://SystemCursors/OpenHand",
	grab = "rbxasset://SystemCursors/ClosedHand",
	point = "rbxasset://SystemCursors/PointingHand",
	
	invisible = "rbxassetid://17335584593",
	
	NS = "rbxasset://SystemCursors/SizeNS",
	EW = "rbxasset://SystemCursors/SizeEW",
	NESW = "rbxasset://SystemCursors/SizeNESW",
	NWSE = "rbxasset://SystemCursors/SizeNWSE",
}

return function(type: types.Cursor, mouse: PluginMouse?)
	(mouse or plugin:GetMouse()).Icon = mouseIcons[type or "default"]
end