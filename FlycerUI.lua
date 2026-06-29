--[[
═══════════════════════════════════════════════════════════════════════════════
    FlycerUI Library v2.0 - COMPLETE VERSION
    Modern Roblox GUI Library with Advanced Features
    
    Author: Flycer
    GitHub: https://github.com/Kyoukara/FlycerUI.lua
    
    Features:
    ✦ Multi-Tab System
    ✦ FPS & Ping Counter
    ✦ Draggable Windows
    ✦ Resize System
    ✦ Toggle Hide/Show
    ✦ Notification System
    ✦ UI Lock System
    ✦ Mobile Support
    
    Usage:
        local FlycerUI = loadstring(game:HttpGet("YOUR_RAW_URL"))()
        
        local Window = FlycerUI:CreateWindow({
            Title = "My Hub",
            Width = 320,
            Height = 245
        })
        
        local Tab = Window:Tab({ Title = "Main" })
        
        Tab:Toggle({
            Title = "Feature Name",
            Default = false,
            Callback = function(state)
                print("Toggled:", state)
            end
        })
        
        -- Access window functions:
        Window.PingLabel.Visible = false
        Window.FPSLabel.Visible = true
        Window.SetUILock(false)
        Window.StartPing()
        Window.StopPing()
        Window.StartFPS()
        Window.StopFPS()
═══════════════════════════════════════════════════════════════════════════════
]]

-- ═══════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════
-- EXECUTOR API CACHE
-- ═══════════════════════════════════════════════════════════

local EXECUTOR_APIS = {
	gethui = false,
	get_hidden_ui = false,
	syn_protect_gui = false,
	protect_gui = false,
	protectgui = false,
	setclipboard = false,
	toclipboard = false,
}

do
	local function envHas(name)
		local ok, val = pcall(function()
			return _G[name] or (getfenv and getfenv(0)[name])
		end)
		return ok and val ~= nil
	end

	if envHas("gethui") then EXECUTOR_APIS.gethui = true end
	if envHas("get_hidden_ui") then EXECUTOR_APIS.get_hidden_ui = true end
	
	pcall(function()
		if syn and type(syn.protect_gui) == "function" then
			EXECUTOR_APIS.syn_protect_gui = true
		end
	end)

	if envHas("protect_gui") then EXECUTOR_APIS.protect_gui = true end
	if envHas("protectgui") then EXECUTOR_APIS.protectgui = true end
	if envHas("setclipboard") then EXECUTOR_APIS.setclipboard = true end
	if envHas("toclipboard") then EXECUTOR_APIS.toclipboard = true end
end

-- ═══════════════════════════════════════════════════════════
-- PLATFORM DETECTION
-- ═══════════════════════════════════════════════════════════

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local isPC = UserInputService.KeyboardEnabled and UserInputService.MouseEnabled

if not isMobile and not isPC then
	isPC = true
end

-- ═══════════════════════════════════════════════════════════
-- CONSTANTS
-- ═══════════════════════════════════════════════════════════

local NOTIF_WIDTH = isMobile and 220 or 265
local NOTIF_HEIGHT = isMobile and 58 or 62
local NOTIF_POS_X = isMobile and 12 or 18
local NOTIF_POS_Y = isMobile and 16 or 22
local NOTIF_CORNER_RADIUS = isMobile and 10 or 12
local NOTIF_PROGRESS_HEIGHT = 3
local NOTIF_ICON_SIZE = isMobile and 26 or 28
local NOTIF_TITLE_SIZE = isMobile and 11 or 12
local NOTIF_BODY_SIZE = isMobile and 9 or 10

local GUI_REF_NAME = "_FlycerGUI_Instance"
local FLAG_NAME = "_FlycerGUI_Loaded"
local FLYCER_TAG_ATTR = "FlycerOwnedGui"

local DRAG_SMOOTHNESS = 14
local EXTRA_FRAME_GAP = 6
local RESIZE_PANEL_WIDTH = 270
local RESIZE_PANEL_HEIGHT = 165
local RESIZE_FIELD_WIDTH = 108
local RESIZE_FIELD_GAP = 14
local FADE_DURATION = 0.4
local TOGGLE_DEBOUNCE = 0.1

local TAB_HEIGHT = 32
local TAB_PADDING = 10
local TAB_MIN_WIDTH = 72
local TAB_RAIL_MARGIN = 5

local HEADER_H = 36
local TAB_RAIL_Y = HEADER_H
local CONTENT_TOP = TAB_RAIL_Y + TAB_HEIGHT + 13

local RESIZE_PANEL_CENTER_POS = UDim2.new(0.5, 0, 0.5, 0)
local RESIZE_PANEL_UP_POS = UDim2.new(0.5, 0, 0.30, 0)

local DISCORD_LINK = "discord.gg/RCASHh828K"

-- ═══════════════════════════════════════════════════════════
-- THEME & TWEEN
-- ═══════════════════════════════════════════════════════════

local RX = {
	Bg1 = Color3.fromRGB(14, 14, 22),
	Bg2 = Color3.fromRGB(20, 20, 30),
	Bg3 = Color3.fromRGB(28, 28, 40),
	Card = Color3.fromRGB(14, 14, 22),
	Accent1 = Color3.fromRGB(88, 101, 242),
	Accent2 = Color3.fromRGB(130, 80, 255),
	Cyan = Color3.fromRGB(0, 200, 255),
	Green = Color3.fromRGB(60, 210, 120),
	Red = Color3.fromRGB(240, 70, 80),
	Orange = Color3.fromRGB(255, 140, 50),
	T1 = Color3.fromRGB(240, 240, 255),
	T2 = Color3.fromRGB(155, 160, 185),
	T3 = Color3.fromRGB(90, 95, 120),
	Border = Color3.fromRGB(45, 48, 70),
	MainAlpha = 0.25,
	CardAlpha = 0.25,
	F1 = Enum.Font.GothamBold,
	F2 = Enum.Font.GothamMedium,
	FM = Enum.Font.Code,
}

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quint)
local TWEEN_NORMAL = TweenInfo.new(0.25, Enum.EasingStyle.Quint)

-- ═══════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════

local Camera = workspace.CurrentCamera

local function getViewportSafe()
	if not Camera then
		Camera = workspace.CurrentCamera
	end
	local vp = Camera.ViewportSize
	if vp.X < 10 or vp.Y < 10 then
		return Vector2.new(1280, 720)
	end
	return vp
end

local function getScreenCenter(w, h)
	local vp = getViewportSafe()
	return UDim2.new(0, math.round((vp.X - w) / 2), 0, math.round((vp.Y - h) / 2))
end

local function getCenteredTogglePos(guiHeight)
	local vp = getViewportSafe()
	local toggleHeight = 34
	local guiY = math.round((vp.Y - guiHeight) / 2)
	local y = guiY + math.round((guiHeight - toggleHeight) / 2)
	return UDim2.new(0, 18, 0, y)
end

local function calcLayout(w, h)
	local SHADOW_OFFSET_Y = -1
	local TAB_SHADOW_OFFSET_Y = 3

	return {
		mainSize = UDim2.new(0, w, 0, h),
		mainPos = getScreenCenter(w, h),
		contentSize = UDim2.new(1, 0, 0, h - CONTENT_TOP - 4),
		shadowSize = UDim2.new(1, -10, 0, h - CONTENT_TOP - 4),
		shadowPos = UDim2.new(0, 5, 0, CONTENT_TOP + SHADOW_OFFSET_Y),
		tabShadowSize = UDim2.new(1, -10, 0, TAB_HEIGHT),
		tabShadowPos = UDim2.new(0, 5, 0, TAB_RAIL_Y + TAB_SHADOW_OFFSET_Y),
		tabRailClipPos = UDim2.new(0, TAB_RAIL_MARGIN, 0, TAB_RAIL_Y + TAB_SHADOW_OFFSET_Y),
		togglePos = getCenteredTogglePos(h),
	}
end

local CHARSET = {}
for i = 33, 126 do
	CHARSET[#CHARSET + 1] = string.char(i)
end

do
	local seed = os.clock() * 1e9 + tick() * 1e6
	math.randomseed(seed)
	for _ = 1, 3 do
		math.random()
	end
end

local function randomName(len)
	len = len or math.random(15, 25)
	local buf = table.create(len)
	for i = 1, len do
		buf[i] = CHARSET[math.random(1, #CHARSET)]
	end
	return table.concat(buf)
end

local g = (getgenv and getgenv()) or _G
local _cachedParent = nil

local function getParent()
	if _cachedParent and _cachedParent.Parent then
		return _cachedParent
	end
	if EXECUTOR_APIS.gethui then
		local ok, r = pcall(gethui)
		if ok and r then
			_cachedParent = r
			return r
		end
	end
	if EXECUTOR_APIS.get_hidden_ui then
		local ok, r = pcall(get_hidden_ui)
		if ok and r then
			_cachedParent = r
			return r
		end
	end
	_cachedParent = CoreGui
	return CoreGui
end

local function SecureGui(gui)
	gui.Name = "F4_" .. randomName(12)
	gui:SetAttribute(FLYCER_TAG_ATTR, true)
	if EXECUTOR_APIS.syn_protect_gui then
		pcall(function()
			syn.protect_gui(gui)
		end)
	end
	if EXECUTOR_APIS.protect_gui then
		pcall(function()
			protect_gui(gui)
		end)
	end
	if EXECUTOR_APIS.protectgui then
		pcall(function()
			protectgui(gui)
		end)
	end
	gui.Parent = getParent()
end

local function getAllContainers()
	local list = { CoreGui }
	if LocalPlayer.PlayerGui then
		table.insert(list, LocalPlayer.PlayerGui)
	end
	if EXECUTOR_APIS.gethui then
		local ok, r = pcall(gethui)
		if ok and r and not table.find(list, r) then
			table.insert(list, r)
		end
	end
	if EXECUTOR_APIS.get_hidden_ui then
		local ok, r = pcall(get_hidden_ui)
		if ok and r and not table.find(list, r) then
			table.insert(list, r)
		end
	end
	return list
end

local function cleanupOldInstances()
	if g[FLAG_NAME] then
		local old = g[GUI_REF_NAME]
		if old and typeof(old) == "Instance" and old.Parent then
			old:Destroy()
		end
	end
	if g._FlycerGUI and typeof(g._FlycerGUI) == "Instance" and g._FlycerGUI.Parent then
		g._FlycerGUI:Destroy()
		g._FlycerGUI = nil
	end
	g[FLAG_NAME] = nil
	g[GUI_REF_NAME] = nil

	for _, container in ipairs(getAllContainers()) do
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("ScreenGui") and child:GetAttribute(FLYCER_TAG_ATTR) == true then
				child:Destroy()
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════
-- STROKE ROTATION MANAGER
-- ═══════════════════════════════════════════════════════════

local _strokeTargets = {}
local _strokeLoopRunning = false
local _strokeConnection = nil

local function registerStrokeTarget(gradObj)
	if not gradObj then
		return
	end
	_strokeTargets[gradObj] = true
	if _strokeLoopRunning then
		return
	end
	_strokeLoopRunning = true
	local rot = 0
	_strokeConnection = RunService.Heartbeat:Connect(function(dt)
		rot = (rot + dt * 40) % 180
		local any = false
		for grad in pairs(_strokeTargets) do
			if grad and grad.Parent then
				grad.Rotation = rot
				any = true
			else
				_strokeTargets[grad] = nil
			end
		end
		if not any then
			_strokeLoopRunning = false
			_strokeConnection:Disconnect()
			_strokeConnection = nil
		end
	end)
end

local function unregisterStrokeTarget(gradObj)
	if gradObj then
		_strokeTargets[gradObj] = nil
	end
end

-- ═══════════════════════════════════════════════════════════
-- SEPARATOR UTILITY
-- ═══════════════════════════════════════════════════════════

local function makeSeparator(parentFrame, posY_offset, useScale, scaleY)
	local sep = Instance.new("Frame")
	sep.Name = "Separator"
	sep.Size = UDim2.new(1, -10, 0, 0)

	if useScale then
		sep.Position = UDim2.new(0, 5, scaleY or 1, posY_offset or 0)
	else
		sep.Position = UDim2.new(0, 5, 0, posY_offset or 0)
	end

	sep.BackgroundTransparency = 1
	sep.BorderSizePixel = 0
	sep.ZIndex = 10
	sep.Active = false
	sep.Selectable = false
	sep:SetAttribute("FlycerTag", true)

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0
	stroke.Parent = sep

	local sg = Instance.new("UIGradient")
	sg.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, RX.Accent1),
		ColorSequenceKeypoint.new(0.45, RX.Accent2),
		ColorSequenceKeypoint.new(0.50, RX.Cyan),
		ColorSequenceKeypoint.new(0.55, RX.Accent2),
		ColorSequenceKeypoint.new(1.00, RX.Accent1),
	})
	sg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 0.55),
		NumberSequenceKeypoint.new(0.20, 0.10),
		NumberSequenceKeypoint.new(0.45, 0.00),
		NumberSequenceKeypoint.new(0.55, 0.00),
		NumberSequenceKeypoint.new(0.80, 0.10),
		NumberSequenceKeypoint.new(1.00, 0.55),
	})
	sg.Parent = stroke
	sep.Parent = parentFrame
	return sep
end

-- ═══════════════════════════════════════════════════════════
-- DRAGGABLE SYSTEM
-- ═══════════════════════════════════════════════════════════

local function getDragLerpAlpha(smoothValue)
	smoothValue = math.clamp(smoothValue or DRAG_SMOOTHNESS, 1, 20)
	return 1.0 - ((smoothValue - 1) / 19) * 0.9
end

local function makeDraggable(dragHandle, dragTarget, smoothness, lockCheckFunc)
	dragTarget = dragTarget or dragHandle

	local dragging = false
	local dragStart = nil
	local startPos = nil
	local activeTouch = nil
	local targetPosition = nil
	local lerpConnection = nil

	local lerpAlpha = getDragLerpAlpha(smoothness)
	local smoothVal = math.clamp(smoothness or DRAG_SMOOTHNESS, 1, 20)
	local useLerp = smoothVal > 3

	local function startLerpLoop()
		if lerpConnection then
			return
		end
		lerpConnection = RunService.Heartbeat:Connect(function()
			if not (dragging and targetPosition) then
				return
			end
			local cp = dragTarget.Position
			local newX = math.round(cp.X.Offset + (targetPosition.X - cp.X.Offset) * lerpAlpha)
			local newY = math.round(cp.Y.Offset + (targetPosition.Y - cp.Y.Offset) * lerpAlpha)

			if math.abs(targetPosition.X - newX) < 0.5 and math.abs(targetPosition.Y - newY) < 0.5 then
				dragTarget.Position =
					UDim2.new(cp.X.Scale, math.round(targetPosition.X), cp.Y.Scale, math.round(targetPosition.Y))
			else
				dragTarget.Position = UDim2.new(cp.X.Scale, newX, cp.Y.Scale, newY)
			end
		end)
	end

	local function stopLerpLoop()
		if lerpConnection then
			lerpConnection:Disconnect()
			lerpConnection = nil
		end
	end

	local function update(input)
		if not (dragging and dragStart and startPos) then
			return
		end
		local delta = input.Position - dragStart
		local rawX = startPos.X.Offset + delta.X
		local rawY = startPos.Y.Offset + delta.Y
		if useLerp then
			targetPosition = Vector2.new(rawX, rawY)
		else
			dragTarget.Position = UDim2.new(startPos.X.Scale, math.round(rawX), startPos.Y.Scale, math.round(rawY))
		end
	end

	local inputChangedConn = nil

	dragHandle.InputBegan:Connect(function(input)
		local it = input.UserInputType
		if it ~= Enum.UserInputType.MouseButton1 and it ~= Enum.UserInputType.Touch then
			return
		end

		-- Check UI Lock
		if lockCheckFunc and lockCheckFunc() then
			return
		end

		if dragging then
			return
		end

		if inputChangedConn then
			inputChangedConn:Disconnect()
			inputChangedConn = nil
		end

		dragging = true
		dragStart = input.Position
		startPos = dragTarget.Position
		targetPosition = Vector2.new(startPos.X.Offset, startPos.Y.Offset)
		if it == Enum.UserInputType.Touch then
			activeTouch = input
		end
		if useLerp then
			startLerpLoop()
		end

		input.Changed:Connect(function()
			if input.UserInputState ~= Enum.UserInputState.End then
				return
			end
			dragging = false
			dragStart = nil
			startPos = nil
			if input == activeTouch then
				activeTouch = nil
			end
			if useLerp then
				task.delay(0.15, function()
					if not dragging then
						stopLerpLoop()
						targetPosition = nil
					end
				end)
			end
			if inputChangedConn then
				inputChangedConn:Disconnect()
				inputChangedConn = nil
			end
		end)

		inputChangedConn = UserInputService.InputChanged:Connect(function(inp)
			if not dragging then
				return
			end
			local t = inp.UserInputType
			if t == Enum.UserInputType.MouseMovement then
				update(inp)
			elseif t == Enum.UserInputType.Touch and inp == activeTouch then
				update(inp)
			end
		end)
	end)

	dragHandle.Destroying:Connect(function()
		stopLerpLoop()
		if inputChangedConn then
			inputChangedConn:Disconnect()
			inputChangedConn = nil
		end
	end)
end

-- ═══════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════

local _notifScreen = nil
local _notifQueue = {}
local _notifRunning = false
local _notifActive = false

local function getNotifSafeParent()
	if LocalPlayer.PlayerGui and LocalPlayer.PlayerGui.Parent then
		return LocalPlayer.PlayerGui
	end
	return CoreGui
end

local function getNotifScreen()
	if _notifScreen and _notifScreen.Parent then
		return _notifScreen
	end
	local sg = Instance.new("ScreenGui")
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.DisplayOrder = 9999999999
	sg.IgnoreGuiInset = true
	sg:SetAttribute(FLYCER_TAG_ATTR, true)
	if EXECUTOR_APIS.syn_protect_gui then
		pcall(function()
			syn.protect_gui(sg)
		end)
	end
	if EXECUTOR_APIS.protect_gui then
		pcall(function()
			protect_gui(sg)
		end)
	end
	sg.Parent = getNotifSafeParent()
	_notifScreen = sg
	return sg
end

local function buildNotifFrame(parent, cfg)
	local title = cfg.title or "Flycer"
	local body = cfg.body or ""

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "NotifFrame"
	mainFrame.Size = UDim2.new(0, NOTIF_WIDTH, 0, NOTIF_HEIGHT)
	mainFrame.Position = UDim2.new(1, NOTIF_WIDTH + 20, 1, -(NOTIF_HEIGHT + NOTIF_POS_Y))
	mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
	mainFrame.BackgroundTransparency = 0.15
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = false
	mainFrame.ZIndex = 2
	mainFrame.Parent = parent

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, NOTIF_CORNER_RADIUS)
	mainCorner.Parent = mainFrame

	local outerStroke = Instance.new("UIStroke")
	outerStroke.Color = Color3.fromRGB(38, 38, 50)
	outerStroke.Thickness = 1
	outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outerStroke.Parent = mainFrame

	local bgGradient = Instance.new("UIGradient")
	bgGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 16, 26)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 14)),
	})
	bgGradient.Rotation = 130
	bgGradient.Parent = mainFrame

	local shimmerClip = Instance.new("Frame")
	shimmerClip.Size = UDim2.new(1, 0, 1, 0)
	shimmerClip.BackgroundTransparency = 1
	shimmerClip.BorderSizePixel = 0
	shimmerClip.ClipsDescendants = true
	shimmerClip.ZIndex = 3
	shimmerClip.Parent = mainFrame

	local shimmerClipCorner = Instance.new("UICorner")
	shimmerClipCorner.CornerRadius = UDim.new(0, NOTIF_CORNER_RADIUS)
	shimmerClipCorner.Parent = shimmerClip

	local shimmer = Instance.new("Frame")
	shimmer.Size = UDim2.new(0, NOTIF_WIDTH * 0.3, 1, 0)
	shimmer.Position = UDim2.new(-0.35, 0, 0, 0)
	shimmer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shimmer.BackgroundTransparency = 0.97
	shimmer.BorderSizePixel = 0
	shimmer.ZIndex = 4
	shimmer.Rotation = 10
	shimmer.Parent = shimmerClip

	local shimmerGrad = Instance.new("UIGradient")
	shimmerGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.9),
		NumberSequenceKeypoint.new(1, 1),
	})
	shimmerGrad.Rotation = 90
	shimmerGrad.Parent = shimmer

	local dividerX = NOTIF_POS_X + NOTIF_ICON_SIZE + 10
	local textOffsetX = dividerX + 11
	local textWidth = NOTIF_WIDTH - textOffsetX - 8

	local iconFrame = Instance.new("Frame")
	iconFrame.Size = UDim2.new(0, NOTIF_ICON_SIZE, 0, NOTIF_ICON_SIZE)
	iconFrame.Position = UDim2.new(0, NOTIF_POS_X, 0.5, 0)
	iconFrame.AnchorPoint = Vector2.new(0, 0.5)
	iconFrame.BackgroundColor3 = Color3.fromRGB(22, 20, 34)
	iconFrame.BorderSizePixel = 0
	iconFrame.ZIndex = 5
	iconFrame.Parent = mainFrame

	local iconFrameCorner = Instance.new("UICorner")
	iconFrameCorner.CornerRadius = UDim.new(0, 8)
	iconFrameCorner.Parent = iconFrame

	local iconFrameStroke = Instance.new("UIStroke")
	iconFrameStroke.Color = Color3.fromRGB(55, 45, 90)
	iconFrameStroke.Thickness = 1
	iconFrameStroke.Parent = iconFrame

	local iconAspect = Instance.new("UIAspectRatioConstraint")
	iconAspect.AspectRatio = 1
	iconAspect.AspectType = Enum.AspectType.ScaleWithParentSize
	iconAspect.DominantAxis = Enum.DominantAxis.Height
	iconAspect.Parent = iconFrame

	local iconImage = Instance.new("ImageLabel")
	iconImage.Size = UDim2.new(0.68, 0, 0.68, 0)
	iconImage.Position = UDim2.new(0.16, 0, 0.16, 0)
	iconImage.BackgroundTransparency = 1
	iconImage.Image = "rbxassetid://89557898457977"
	iconImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
	iconImage.ScaleType = Enum.ScaleType.Fit
	iconImage.ZIndex = 6
	iconImage.Parent = iconFrame

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(0, 1, 0, NOTIF_HEIGHT * 0.55)
	divider.Position = UDim2.new(0, dividerX, 0.5, 0)
	divider.AnchorPoint = Vector2.new(0, 0.5)
	divider.BackgroundColor3 = Color3.fromRGB(55, 45, 90)
	divider.BorderSizePixel = 0
	divider.ZIndex = 5
	divider.Parent = mainFrame

	local textContainer = Instance.new("Frame")
	textContainer.Size = UDim2.new(0, textWidth, 1, -(NOTIF_PROGRESS_HEIGHT + 3))
	textContainer.Position = UDim2.new(0, textOffsetX, 0, 0)
	textContainer.BackgroundTransparency = 1
	textContainer.ZIndex = 5
	textContainer.Parent = mainFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 15)
	titleLabel.Position = UDim2.new(0, 0, 0, 13)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(225, 215, 255)
	titleLabel.TextSize = NOTIF_TITLE_SIZE
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.ZIndex = 6
	titleLabel.Parent = textContainer

	local bodyLabel = Instance.new("TextLabel")
	bodyLabel.Size = UDim2.new(1, 0, 0, 12)
	bodyLabel.Position = UDim2.new(0, 0, 0, 30)
	bodyLabel.BackgroundTransparency = 1
	bodyLabel.Text = body
	bodyLabel.TextColor3 = Color3.fromRGB(110, 105, 135)
	bodyLabel.TextSize = NOTIF_BODY_SIZE
	bodyLabel.Font = Enum.Font.Gotham
	bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
	bodyLabel.TextTruncate = Enum.TextTruncate.AtEnd
	bodyLabel.ZIndex = 6
	bodyLabel.Parent = textContainer

	local progressContainer = Instance.new("Frame")
	progressContainer.Name = "ProgressContainer"
	progressContainer.Size = UDim2.new(1, -(NOTIF_CORNER_RADIUS * 2), 0, NOTIF_PROGRESS_HEIGHT)
	progressContainer.Position = UDim2.new(0, NOTIF_CORNER_RADIUS, 1, -(NOTIF_PROGRESS_HEIGHT + 3))
	progressContainer.BackgroundColor3 = Color3.fromRGB(30, 28, 42)
	progressContainer.BorderSizePixel = 0
	progressContainer.ZIndex = 9
	progressContainer.Parent = mainFrame

	local progressContainerCorner = Instance.new("UICorner")
	progressContainerCorner.CornerRadius = UDim.new(1, 0)
	progressContainerCorner.Parent = progressContainer

	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(1, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(0, 240, 255)
	progressFill.BorderSizePixel = 0
	progressFill.ZIndex = 10
	progressFill.Parent = progressContainer

	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(1, 0)
	progressFillCorner.Parent = progressFill

	local progressGrad = Instance.new("UIGradient")
	progressGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 240, 255)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 120, 255)),
		ColorSequenceKeypoint.new(0.66, Color3.fromRGB(180, 0, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 160)),
	})
	progressGrad.Parent = progressFill

	return mainFrame, progressFill, shimmer
end

local function normalizeNotifCfg(cfg)
	return {
		title = cfg.title or cfg.Title or "Flycer",
		body = cfg.body or cfg.Description or "",
		duration = cfg.duration or cfg.Duration or 5,
		onComplete = cfg.onComplete or cfg.OnComplete,
	}
end

local function processNotifQueue()
	if _notifRunning then
		return
	end
	_notifRunning = true

	task.spawn(function()
		while #_notifQueue > 0 do
			local cfg = table.remove(_notifQueue, 1)
			local duration = cfg.duration
			local onComplete = cfg.onComplete

			_notifActive = true

			local screen = getNotifScreen()
			local notifFrame, progressFill, shimmer = buildNotifFrame(screen, cfg)

			local targetPos = UDim2.new(1, -(NOTIF_WIDTH + NOTIF_POS_X), 1, -(NOTIF_HEIGHT + NOTIF_POS_Y))
			local exitPos = UDim2.new(1, NOTIF_WIDTH + 20, 1, -(NOTIF_HEIGHT + NOTIF_POS_Y))

			local slideInInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			local slideOutInfo = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

			TweenService:Create(notifFrame, slideInInfo, { Position = targetPos }):Play()

			local shimmerActive = true
			local shimmerThread = task.spawn(function()
				while shimmerActive and notifFrame and notifFrame.Parent do
					shimmer.Position = UDim2.new(-0.35, 0, 0, 0)
					local tw = TweenService:Create(
						shimmer,
						TweenInfo.new(1.5, Enum.EasingStyle.Linear),
						{ Position = UDim2.new(1.2, 0, 0, 0) }
					)
					tw:Play()
					tw.Completed:Wait()
					if shimmerActive then
						task.wait(1.7)
					end
				end
			end)

			TweenService
				:Create(
					progressFill,
					TweenInfo.new(duration, Enum.EasingStyle.Linear),
					{ Size = UDim2.new(0, 0, 1, 0) }
				)
				:Play()

			task.wait(duration)

			shimmerActive = false
			pcall(task.cancel, shimmerThread)
			shimmerThread = nil

			local slideOut = TweenService:Create(notifFrame, slideOutInfo, { Position = exitPos })
			slideOut:Play()
			slideOut.Completed:Wait()

			if notifFrame and notifFrame.Parent then
				notifFrame:Destroy()
			end

			if _notifScreen and _notifScreen.Parent then
				if #_notifScreen:GetChildren() == 0 then
					_notifScreen:Destroy()
					_notifScreen = nil
				end
			end

			_notifActive = false

			if typeof(onComplete) == "function" then
				task.spawn(onComplete)
			end
			if #_notifQueue > 0 then
				task.wait(0.2)
			end
		end
		_notifRunning = false
	end)
end

local function ShowNotification(cfg)
	if _notifActive then
		return
	end

	cfg = normalizeNotifCfg(cfg or {})
	table.insert(_notifQueue, cfg)
	processNotifQueue()
end

-- ═══════════════════════════════════════════════════════════
-- MAIN LIBRARY
-- ═══════════════════════════════════════════════════════════

local FlycerUI = {}
FlycerUI.__index = FlycerUI
FlycerUI.Version = "2.0.0"

function FlycerUI:CreateWindow(config)
	cleanupOldInstances()
	task.wait(0.05)

	local Window = {}
	Window.Title = config.Title or "FlycerUI"
	Window.Width = math.clamp(config.Width or 320, 150, 800)
	Window.Height = math.clamp(config.Height or 245, 100, 700)
	Window.Tabs = {}
	Window.ActiveTab = nil
	Window.PingConnection = nil
	Window.FPSConnection = nil
	Window.UILocked = false

	g.FlycerGUIWidth = Window.Width
	g.FlycerGUIHeight = Window.Height
	g.FlycerUILocked = false

	local MainGui = Instance.new("ScreenGui")
	MainGui.ResetOnSpawn = false
	MainGui.IgnoreGuiInset = true
	MainGui.Archivable = false
	MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	MainGui.DisplayOrder = 999999998
	SecureGui(MainGui)

	g._FlycerGUI = MainGui
	g[GUI_REF_NAME] = MainGui
	g[FLAG_NAME] = true

	local initLayout = calcLayout(Window.Width, Window.Height)

	-- ════════════════════════════════════════════════════════
	-- MAIN FRAME
	-- ════════════════════════════════════════════════════════

	local MainFrame = Instance.new("Frame")
	MainFrame.Name = randomName()
	MainFrame.Size = initLayout.mainSize
	MainFrame.Position = initLayout.mainPos
	MainFrame.BackgroundColor3 = RX.Bg1
	MainFrame.BackgroundTransparency = RX.MainAlpha
	MainFrame.BorderSizePixel = 0
	MainFrame.ZIndex = 2
	MainFrame.Active = true
	MainFrame.ClipsDescendants = false
	MainFrame:SetAttribute("FlycerTag", true)
	MainFrame.Visible = true
	MainFrame.Parent = MainGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 10)
	mainCorner.Parent = MainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Thickness = 2
	mainStroke.Transparency = 0.2
	mainStroke.Color = RX.T1
	mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	mainStroke.Parent = MainFrame

	local mainStrokeGrad = Instance.new("UIGradient")
	mainStrokeGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 60, 100)),
		ColorSequenceKeypoint.new(0.35, RX.Accent1),
		ColorSequenceKeypoint.new(0.65, RX.Accent2),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 60, 100)),
	})
	mainStrokeGrad.Rotation = 135
	mainStrokeGrad.Parent = mainStroke
	registerStrokeTarget(mainStrokeGrad)

	MainFrame.Destroying:Connect(function()
		unregisterStrokeTarget(mainStrokeGrad)
	end)

	local glassOverlay = Instance.new("Frame")
	glassOverlay.Name = "GlassOverlay"
	glassOverlay.Size = UDim2.new(1, 0, 0, 38)
	glassOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	glassOverlay.BackgroundTransparency = 0.96
	glassOverlay.BorderSizePixel = 0
	glassOverlay.ZIndex = 1
	glassOverlay.Parent = MainFrame

	local glassCorner = Instance.new("UICorner")
	glassCorner.CornerRadius = UDim.new(0, 12)
	glassCorner.Parent = glassOverlay

	local glassGrad = Instance.new("UIGradient")
	glassGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.88),
		NumberSequenceKeypoint.new(0.4, 0.96),
		NumberSequenceKeypoint.new(1, 1),
	})
	glassGrad.Rotation = 90
	glassGrad.Parent = glassOverlay

	local innerGrad = Instance.new("UIGradient")
	innerGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 28)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 14, 22)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 18)),
	})
	innerGrad.Rotation = 180
	innerGrad.Parent = MainFrame

	-- ════════════════════════════════════════════════════════
	-- HEADER
	-- ════════════════════════════════════════════════════════

	local Header = Instance.new("Frame")
	Header.Name = "Header"
	Header.Size = UDim2.new(1, 0, 0, HEADER_H)
	Header.BackgroundTransparency = 1
	Header.BorderSizePixel = 0
	Header.ZIndex = 10
	Header.Parent = MainFrame
	
	local function isUILocked()
		return Window.UILocked
	end
	makeDraggable(Header, MainFrame, nil, isUILocked)

	local headerIcon = Instance.new("ImageLabel")
	headerIcon.Size = UDim2.new(0, 20, 0, 20)
	headerIcon.Position = UDim2.new(0, 5, 0.5, 0)
	headerIcon.AnchorPoint = Vector2.new(0, 0.5)
	headerIcon.BackgroundTransparency = 1
	headerIcon.Image = "rbxassetid://89557898457977"
	headerIcon.ZIndex = 11
	headerIcon.Parent = Header

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -160, 1, 0)
	titleLabel.Position = UDim2.new(0, 28, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = Window.Title
	titleLabel.TextColor3 = RX.T1
	titleLabel.Font = RX.F1
	titleLabel.TextSize = 11
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.ZIndex = 11
	titleLabel.Parent = Header

	local titleGrad = Instance.new("UIGradient")
	titleGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, RX.T1),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 185, 255)),
		ColorSequenceKeypoint.new(1, RX.Accent2),
	})
	titleGrad.Parent = titleLabel

	makeSeparator(Header, 0, true, 1)

	-- ════════════════════════════════════════════════════════
	-- PING COUNTER
	-- ════════════════════════════════════════════════════════

	local PING_COLOR = Color3.fromRGB(60, 210, 120)
	local PING_UPDATE_INTERVAL = 0.25

	Window.PingLabel = Instance.new("TextLabel")
	Window.PingLabel.Name = "PingLabel"
	Window.PingLabel.Position = UDim2.new(1, -120, 0.5, 0)
	Window.PingLabel.AnchorPoint = Vector2.new(0, 0.5)
	Window.PingLabel.Size = UDim2.new(0, 55, 0, 16)
	Window.PingLabel.BackgroundColor3 = RX.Accent1
	Window.PingLabel.BackgroundTransparency = 0.85
	Window.PingLabel.Text = "PING: 0ms"
	Window.PingLabel.Font = RX.F1
	Window.PingLabel.TextSize = 9
	Window.PingLabel.TextColor3 = PING_COLOR
	Window.PingLabel.BorderSizePixel = 0
	Window.PingLabel.ZIndex = 11
	Window.PingLabel.Parent = Header

	local pingCorner = Instance.new("UICorner")
	pingCorner.CornerRadius = UDim.new(0, 6)
	pingCorner.Parent = Window.PingLabel

	local pingStroke = Instance.new("UIStroke")
	pingStroke.Thickness = 1
	pingStroke.Color = RX.Accent1
	pingStroke.Transparency = 0.5
	pingStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pingStroke.Parent = Window.PingLabel

	local lastPingUpdate = 0

	local function GetPing()
		local ok, result = pcall(function()
			return LocalPlayer:GetNetworkPing()
		end)
		if ok and result and result == result then
			return math.round(math.max(result * 1000, 0))
		end
		return 0
	end

	function Window.StartPing()
		if Window.PingConnection then
			Window.PingConnection:Disconnect()
			Window.PingConnection = nil
		end
		lastPingUpdate = os.clock()
		Window.PingConnection = RunService.Heartbeat:Connect(function()
			local now = os.clock()
			if now - lastPingUpdate < PING_UPDATE_INTERVAL then
				return
			end
			lastPingUpdate = now
			if Window.PingLabel and Window.PingLabel.Parent then
				Window.PingLabel.Text = "PING: " .. tostring(GetPing()) .. "ms"
				Window.PingLabel.TextColor3 = PING_COLOR
			end
		end)
	end

	function Window.StopPing()
		if Window.PingConnection then
			Window.PingConnection:Disconnect()
			Window.PingConnection = nil
		end
		if Window.PingLabel and Window.PingLabel.Parent then
			Window.PingLabel.Text = "PING: 0ms"
			Window.PingLabel.TextColor3 = PING_COLOR
		end
	end

	MainGui.Destroying:Connect(Window.StopPing)

	-- ════════════════════════════════════════════════════════
	-- FPS COUNTER
	-- ════════════════════════════════════════════════════════

	local FPS_COLOR = Color3.fromRGB(240, 220, 50)
	local FPS_UPDATE_INTERVAL = 0.25

	Window.FPSLabel = Instance.new("TextLabel")
	Window.FPSLabel.Name = "FPSLabel"
	Window.FPSLabel.Position = UDim2.new(1, -62, 0.5, 0)
	Window.FPSLabel.AnchorPoint = Vector2.new(0, 0.5)
	Window.FPSLabel.Size = UDim2.new(0, 55, 0, 16)
	Window.FPSLabel.BackgroundColor3 = RX.Accent1
	Window.FPSLabel.BackgroundTransparency = 0.85
	Window.FPSLabel.Text = "FPS: 0"
	Window.FPSLabel.Font = RX.F1
	Window.FPSLabel.TextSize = 9
	Window.FPSLabel.TextColor3 = FPS_COLOR
	Window.FPSLabel.BorderSizePixel = 0
	Window.FPSLabel.ZIndex = 11
	Window.FPSLabel.Parent = Header

	local fpsCorner = Instance.new("UICorner")
	fpsCorner.CornerRadius = UDim.new(0, 6)
	fpsCorner.Parent = Window.FPSLabel

	local fpsStroke = Instance.new("UIStroke")
	fpsStroke.Thickness = 1
	fpsStroke.Color = RX.Accent1
	fpsStroke.Transparency = 0.5
	fpsStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	fpsStroke.Parent = Window.FPSLabel

	local frameCount = 0
	local lastUpdateTime = 0

	function Window.StartFPS()
		if Window.FPSConnection then
			Window.FPSConnection:Disconnect()
			Window.FPSConnection = nil
		end
		frameCount = 0
		lastUpdateTime = os.clock()

		local function fpsCallback()
			frameCount = frameCount + 1
			local now = os.clock()
			local elapsed = now - lastUpdateTime
			if elapsed >= FPS_UPDATE_INTERVAL then
				if Window.FPSLabel and Window.FPSLabel.Parent then
					Window.FPSLabel.Text = "FPS: " .. tostring(math.round(frameCount / elapsed))
					Window.FPSLabel.TextColor3 = FPS_COLOR
				end
				frameCount = 0
				lastUpdateTime = now
			end
		end

		local ok = pcall(function()
			Window.FPSConnection = RunService.RenderStepped:Connect(fpsCallback)
		end)
		if not ok then
			Window.FPSConnection = RunService.Heartbeat:Connect(fpsCallback)
		end
	end

	function Window.StopFPS()
		if Window.FPSConnection then
			Window.FPSConnection:Disconnect()
			Window.FPSConnection = nil
		end
		if Window.FPSLabel and Window.FPSLabel.Parent then
			Window.FPSLabel.Text = "FPS: 0"
			Window.FPSLabel.TextColor3 = FPS_COLOR
		end
	end

	MainGui.Destroying:Connect(Window.StopFPS)

	-- ════════════════════════════════════════════════════════
	-- UI LOCK FUNCTION
	-- ════════════════════════════════════════════════════════

	function Window.SetUILock(locked)
		Window.UILocked = locked
		g.FlycerUILocked = locked

		ShowNotification({
			title = "UI Position " .. (locked and "LOCKED" or "UNLOCKED"),
			body = locked and "Drag disabled - position locked" or "Drag enabled - position unlocked",
			duration = 2.1,
		})
	end

	-- ════════════════════════════════════════════════════════
	-- TAB SYSTEM
	-- ════════════════════════════════════════════════════════

	local TabShadowFrame = Instance.new("Frame")
	TabShadowFrame.Name = "TabShadowFrame"
	TabShadowFrame.Size = initLayout.tabShadowSize
	TabShadowFrame.Position = initLayout.tabShadowPos
	TabShadowFrame.BackgroundColor3 = RX.Accent1
	TabShadowFrame.BackgroundTransparency = 0.6
	TabShadowFrame.BorderSizePixel = 0
	TabShadowFrame.ZIndex = 1
	TabShadowFrame.Parent = MainFrame

	local TabShadowCorner = Instance.new("UICorner")
	TabShadowCorner.CornerRadius = UDim.new(0, 3)
	TabShadowCorner.Parent = TabShadowFrame

	local TabRailClip = Instance.new("Frame")
	TabRailClip.Name = "TabRailClip"
	TabRailClip.Size = UDim2.new(1, -TAB_RAIL_MARGIN * 2, 0, TAB_HEIGHT)
	TabRailClip.Position = initLayout.tabRailClipPos
	TabRailClip.BackgroundTransparency = 1
	TabRailClip.BorderSizePixel = 0
	TabRailClip.ClipsDescendants = true
	TabRailClip.ZIndex = 8
	TabRailClip.Parent = MainFrame

	local TabScroll = Instance.new("ScrollingFrame")
	TabScroll.Name = "TabScroll"
	TabScroll.Size = UDim2.new(1, 0, 1, 0)
	TabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	TabScroll.ScrollingDirection = Enum.ScrollingDirection.X
	TabScroll.ScrollingEnabled = true
	TabScroll.BackgroundTransparency = 1
	TabScroll.BorderSizePixel = 0
	TabScroll.ZIndex = 8
	TabScroll.ElasticBehavior = Enum.ElasticBehavior.Never
	TabScroll.Parent = TabRailClip

	if isMobile then
		TabScroll.ScrollBarThickness = 1
		TabScroll.ScrollBarImageTransparency = 1
		TabScroll.ScrollBarImageColor3 = RX.Accent1
	else
		TabScroll.ScrollBarThickness = 0
	end

	local tabListLayout = Instance.new("UIListLayout")
	tabListLayout.FillDirection = Enum.FillDirection.Horizontal
	tabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabListLayout.Padding = UDim.new(0, 4)
	tabListLayout.Parent = TabScroll

	local tabPad = Instance.new("UIPadding")
	tabPad.PaddingLeft = UDim.new(0, 4)
	tabPad.PaddingRight = UDim.new(0, 4)
	tabPad.Parent = TabScroll

	makeSeparator(MainFrame, TAB_RAIL_Y + TAB_HEIGHT + 6, false)

	-- ════════════════════════════════════════════════════════
	-- CONTENT AREA
	-- ════════════════════════════════════════════════════════

	local ShadowFrame = Instance.new("Frame")
	ShadowFrame.Name = "ShadowFrame"
	ShadowFrame.Size = initLayout.shadowSize
	ShadowFrame.Position = initLayout.shadowPos
	ShadowFrame.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
	ShadowFrame.BackgroundTransparency = 0.8
	ShadowFrame.BorderSizePixel = 0
	ShadowFrame.ZIndex = 1
	ShadowFrame.Parent = MainFrame

	local ShadowCorner = Instance.new("UICorner")
	ShadowCorner.CornerRadius = UDim.new(0, 8)
	ShadowCorner.Parent = ShadowFrame

	local ContentWrapper = Instance.new("Frame")
	ContentWrapper.Name = "ContentWrapper"
	ContentWrapper.Size = initLayout.contentSize
	ContentWrapper.AutomaticSize = Enum.AutomaticSize.None
	ContentWrapper.Position = UDim2.new(0, 0, 0, CONTENT_TOP)
	ContentWrapper.BackgroundTransparency = 1
	ContentWrapper.BorderSizePixel = 0
	ContentWrapper.ClipsDescendants = true
	ContentWrapper.ZIndex = 5
	ContentWrapper.Parent = MainFrame

	-- ════════════════════════════════════════════════════════
	-- TAB FUNCTIONS
	-- ════════════════════════════════════════════════════════

	local tabSwitchDebounce = false

	local function makeTabCanvas()
		local sf = Instance.new("ScrollingFrame")
		sf.Size = UDim2.new(1, 0, 1, 0)
		sf.CanvasSize = UDim2.new(0, 0, 0, 0)
		sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
		sf.ScrollingDirection = Enum.ScrollingDirection.Y
		sf.ScrollingEnabled = true
		sf.ScrollBarThickness = 3
		sf.ScrollBarImageColor3 = RX.Accent1
		sf.ScrollBarImageTransparency = 1
		sf.BackgroundTransparency = 1
		sf.BorderSizePixel = 0
		sf.ZIndex = 5
		sf.ElasticBehavior = Enum.ElasticBehavior.Never
		sf.Visible = false
		sf.Parent = ContentWrapper

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 10)
		pad.PaddingRight = UDim.new(0, 10)
		pad.PaddingTop = UDim.new(0, 6)
		pad.PaddingBottom = UDim.new(0, 6)
		pad.Parent = sf

		local layout = Instance.new("UIListLayout")
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.Padding = UDim.new(0, 5)
		layout.Parent = sf

		return sf, layout
	end

	local function activateTab(name)
		if tabSwitchDebounce then
			return
		end
		if Window.ActiveTab and Window.ActiveTab.Title == name then
			return
		end
		tabSwitchDebounce = true

		local INACTIVE_BG = Color3.fromRGB(22, 22, 34)
		local ACTIVE_BG = Color3.fromRGB(32, 32, 52)

		for _, tab in ipairs(Window.Tabs) do
			local active = (tab.Title == name)
			tab.Canvas.Visible = active
			TweenService:Create(tab.Button, TWEEN_FAST, {
				BackgroundColor3 = active and ACTIVE_BG or INACTIVE_BG,
				BackgroundTransparency = active and 0 or 0.3,
			}):Play()
			TweenService:Create(tab.Label, TWEEN_FAST, {
				TextColor3 = active and RX.T1 or RX.T3,
			}):Play()
			TweenService:Create(tab.Stroke, TWEEN_FAST, {
				Transparency = active and 0.3 or 0.8,
				Color = active and RX.Accent1 or RX.Border,
			}):Play()
			
			if active then
				Window.ActiveTab = tab
			end
		end

		task.delay(0.18, function()
			tabSwitchDebounce = false
		end)
	end

	-- ════════════════════════════════════════════════════════
	-- WINDOW API: TAB CREATION
	-- ════════════════════════════════════════════════════════

	function Window:Tab(config)
		local Tab = {}
		Tab.Title = config.Title or "Tab"
		Tab.LayoutOrder = config.LayoutOrder or (#Window.Tabs + 1)
		Tab.Elements = {}

		Tab.Canvas, Tab.Layout = makeTabCanvas()

		local estimatedW = math.max(TAB_MIN_WIDTH, string.len(Tab.Title) * 7 + TAB_PADDING * 2)

		Tab.Button = Instance.new("Frame")
		Tab.Button.Name = "Tab_" .. Tab.Title
		Tab.Button.Size = UDim2.new(0, estimatedW, 0, TAB_HEIGHT - 7)
		Tab.Button.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
		Tab.Button.BackgroundTransparency = 0.3
		Tab.Button.BorderSizePixel = 0
		Tab.Button.LayoutOrder = Tab.LayoutOrder
		Tab.Button.ZIndex = 9
		Tab.Button.Parent = TabScroll

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 5)
		btnCorner.Parent = Tab.Button

		Tab.Stroke = Instance.new("UIStroke")
		Tab.Stroke.Thickness = 1
		Tab.Stroke.Color = RX.Border
		Tab.Stroke.Transparency = 0.8
		Tab.Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Tab.Stroke.Parent = Tab.Button

		Tab.Label = Instance.new("TextLabel")
		Tab.Label.Size = UDim2.new(1, -TAB_PADDING, 1, 0)
		Tab.Label.Position = UDim2.new(0, TAB_PADDING / 2, 0, 0)
		Tab.Label.BackgroundTransparency = 1
		Tab.Label.Text = Tab.Title
		Tab.Label.Font = RX.F1
		Tab.Label.TextSize = 11
		Tab.Label.TextColor3 = RX.T3
		Tab.Label.TextXAlignment = Enum.TextXAlignment.Center
		Tab.Label.TextYAlignment = Enum.TextYAlignment.Center
		Tab.Label.ZIndex = 10
		Tab.Label.Parent = Tab.Button

		local hitbox = Instance.new("TextButton")
		hitbox.Size = UDim2.new(1, 0, 1, 0)
		hitbox.BackgroundTransparency = 1
		hitbox.Text = ""
		hitbox.ZIndex = 12
		hitbox.Parent = Tab.Button

		if not isMobile then
			hitbox.MouseEnter:Connect(function()
				if Window.ActiveTab ~= Tab then
					TweenService:Create(Tab.Button, TWEEN_FAST, { BackgroundTransparency = 0.1 }):Play()
					TweenService:Create(Tab.Label, TWEEN_FAST, { TextColor3 = RX.T2 }):Play()
				end
			end)
			hitbox.MouseLeave:Connect(function()
				if Window.ActiveTab ~= Tab then
					TweenService:Create(Tab.Button, TWEEN_FAST, { BackgroundTransparency = 0.3 }):Play()
					TweenService:Create(Tab.Label, TWEEN_FAST, { TextColor3 = RX.T3 }):Play()
				end
			end)
		end

		hitbox.Activated:Connect(function()
			activateTab(Tab.Title)
		end)

		table.insert(Window.Tabs, Tab)

		if #Window.Tabs == 1 then
			activateTab(Tab.Title)
		end

		-- ════════════════════════════════════════════════════
		-- TAB COMPONENTS
		-- ════════════════════════════════════════════════════

		local function makeBaseCard(layoutOrder, height)
			local f = Instance.new("Frame")
			f.Name = randomName()
			f.Size = UDim2.new(1, 0, 0, height or 34)
			f.BackgroundColor3 = RX.Card
			f.BackgroundTransparency = RX.CardAlpha
			f.BorderSizePixel = 0
			f.LayoutOrder = layoutOrder or 99
			f.Parent = Tab.Canvas

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = f

			local cardStroke = Instance.new("UIStroke")
			cardStroke.Thickness = 1
			cardStroke.Color = RX.Border
			cardStroke.Transparency = 0.6
			cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			cardStroke.Parent = f
			return f
		end

		function Tab:Label(config)
			config = config or {}
			local text = config.Title or config.title or "Label"
			local layoutOrder = config.LayoutOrder or config.layoutOrder or 99

			local f = makeBaseCard(layoutOrder, 24)
			f.BackgroundColor3 = RX.Bg3

			local lb = Instance.new("Frame")
			lb.Size = UDim2.new(0, 3, 0.5, 0)
			lb.Position = UDim2.new(0, 6, 0.5, 0)
			lb.AnchorPoint = Vector2.new(0, 0.5)
			lb.BackgroundColor3 = RX.Accent1
			lb.BorderSizePixel = 0
			lb.Parent = f

			local lbc = Instance.new("UICorner")
			lbc.CornerRadius = UDim.new(1, 0)
			lbc.Parent = lb

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -22, 1, 0)
			lbl.Position = UDim2.new(0, 16, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = text
			lbl.TextColor3 = RX.T2
			lbl.Font = RX.F1
			lbl.TextSize = 11
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = f

			return {
				Frame = f,
				SetText = function(newText)
					lbl.Text = newText
				end,
				Destroy = function()
					if f and f.Parent then
						f:Destroy()
					end
				end,
			}
		end

		function Tab:Section(config)
			config = config or {}
			local title = config.Title or config.title or "Section"
			local layoutOrder = config.LayoutOrder or config.layoutOrder or 50

			local container = Instance.new("Frame")
			container.Name = randomName()
			container.Size = UDim2.new(1, 0, 0, 26)
			container.BackgroundTransparency = 1
			container.LayoutOrder = layoutOrder
			container.Parent = Tab.Canvas

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -8, 1, 0)
			label.Position = UDim2.new(0, 4, 0, 0)
			label.BackgroundTransparency = 1
			label.Text = string.upper(title)
			label.TextColor3 = RX.T2
			label.Font = RX.F1
			label.TextSize = 10
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = container

			local accentLine = Instance.new("Frame")
			accentLine.Size = UDim2.new(1, -4, 0, 1)
			accentLine.Position = UDim2.new(0, 2, 1, -1)
			accentLine.BackgroundColor3 = RX.Accent1
			accentLine.BackgroundTransparency = 0.2
			accentLine.BorderSizePixel = 0
			accentLine.Parent = container

			local lg = Instance.new("UIGradient")
			lg.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.6, 0.4),
				NumberSequenceKeypoint.new(1, 1),
			})
			lg.Parent = accentLine

			return {
				Frame = container,
				SetTitle = function(newTitle)
					label.Text = string.upper(newTitle)
				end,
				Destroy = function()
					if container and container.Parent then
						container:Destroy()
					end
				end,
			}
		end

		function Tab:Button(config)
			config = config or {}

			local title = config.Title or config.title or config.Label or config.label or "Button"
			local layoutOrder = config.LayoutOrder or config.layoutOrder or 99
			local lockedState = config.Locked == true or config.locked == true
			local debounceTime = tonumber(config.Debounce or config.debounce) or 0.3
			local callback = config.Callback or config.callback or config.onClick

			local frame = makeBaseCard(layoutOrder, 36)

			local titleLabel = Instance.new("TextLabel")
			titleLabel.Size = UDim2.new(1, -80, 1, 0)
			titleLabel.Position = UDim2.new(0, 10, 0, 0)
			titleLabel.BackgroundTransparency = 1
			titleLabel.Text = title
			titleLabel.Font = RX.F1
			titleLabel.TextSize = 10
			titleLabel.TextColor3 = RX.T1
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel.TextYAlignment = Enum.TextYAlignment.Center
			titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			titleLabel.Parent = frame

			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 60, 0, 24)
			btn.Position = UDim2.new(1, -70, 0.5, 0)
			btn.AnchorPoint = Vector2.new(0, 0.5)
			btn.BackgroundColor3 = RX.Accent1
			btn.BackgroundTransparency = 0.15
			btn.Text = "RUN"
			btn.Font = RX.F1
			btn.TextSize = 10
			btn.TextColor3 = RX.T1
			btn.AutoButtonColor = false
			btn.BorderSizePixel = 0
			btn.Parent = frame

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 7)
			btnCorner.Parent = btn

			local btnGrad = Instance.new("UIGradient")
			btnGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, RX.Accent1),
				ColorSequenceKeypoint.new(1, RX.Accent2),
			})
			btnGrad.Rotation = 90
			btnGrad.Parent = btn

			local btnStroke = Instance.new("UIStroke")
			btnStroke.Thickness = 1
			btnStroke.Color = RX.Accent1
			btnStroke.Transparency = 0.5
			btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			btnStroke.Parent = btn

			local locked = lockedState
			local isDebounced = false

			local function updateLockedVisuals(instant)
				local tweenInfo = instant and TweenInfo.new(0) or TWEEN_FAST

				TweenService:Create(titleLabel, tweenInfo, {
					TextTransparency = locked and 0.35 or 0,
				}):Play()

				TweenService:Create(btn, tweenInfo, {
					BackgroundTransparency = locked and 0.5 or 0.15,
					TextTransparency = locked and 0.35 or 0,
				}):Play()
			end

			updateLockedVisuals(true)

			btn.Activated:Connect(function()
				if locked then
					return
				end

				if isDebounced then
					return
				end

				isDebounced = true

				TweenService:Create(btn, TWEEN_FAST, {
					BackgroundTransparency = 0,
				}):Play()

				task.delay(0.15, function()
					if btn and btn.Parent then
						TweenService:Create(btn, TWEEN_FAST, {
							BackgroundTransparency = 0.15,
						}):Play()
					end
				end)

				if typeof(callback) == "function" then
					task.spawn(callback)
				end

				task.delay(debounceTime, function()
					isDebounced = false
				end)
			end)

			if not isMobile then
				btn.MouseEnter:Connect(function()
					if not locked then
						TweenService:Create(btn, TWEEN_FAST, {
							BackgroundTransparency = 0,
						}):Play()
						TweenService:Create(btnStroke, TWEEN_FAST, {
							Transparency = 0.2,
						}):Play()
					end
				end)
				btn.MouseLeave:Connect(function()
					if not locked then
						TweenService:Create(btn, TWEEN_FAST, {
							BackgroundTransparency = 0.15,
						}):Play()
						TweenService:Create(btnStroke, TWEEN_FAST, {
							Transparency = 0.5,
						}):Play()
					end
				end)
			end

			return {
				Frame = frame,
				Button = btn,

				SetCallback = function(fn)
					callback = fn
				end,

				SetLocked = function(v)
					locked = v == true
					updateLockedVisuals(false)
				end,

				GetLocked = function()
					return locked
				end,

				SetTitle = function(newTitle)
					titleLabel.Text = newTitle
				end,

				Destroy = function()
					if frame and frame.Parent then
						frame:Destroy()
					end
				end,
			}
		end

		function Tab:Toggle(config)
			config = config or {}

			local title = config.Title or config.title or config.Label or config.label or "Toggle"
			local layoutOrder = config.LayoutOrder or config.layoutOrder or 99
			local defaultState = config.Default == true or config.default == true
			local lockedState = config.Locked == true or config.locked == true
			local debounceTime = tonumber(config.Debounce or config.debounce) or 0.3
			local callback = config.Callback or config.callback or config.onToggle

			local frame = makeBaseCard(layoutOrder, 34)

			local titleLabel = Instance.new("TextLabel")
			titleLabel.Size = UDim2.new(1, -74, 1, 0)
			titleLabel.Position = UDim2.new(0, 10, 0, 0)
			titleLabel.BackgroundTransparency = 1
			titleLabel.Text = title
			titleLabel.Font = RX.F1
			titleLabel.TextSize = 10
			titleLabel.TextColor3 = RX.T1
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel.TextYAlignment = Enum.TextYAlignment.Center
			titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			titleLabel.Parent = frame

			local track = Instance.new("Frame")
			track.Size = UDim2.new(0, 44, 0, 22)
			track.Position = UDim2.new(1, -53, 0.5, 0)
			track.AnchorPoint = Vector2.new(0, 0.5)
			track.BackgroundColor3 = Color3.fromRGB(38, 38, 55)
			track.BorderSizePixel = 0
			track.Parent = frame

			local trackCorner = Instance.new("UICorner")
			trackCorner.CornerRadius = UDim.new(1, 0)
			trackCorner.Parent = track

			local trackStroke = Instance.new("UIStroke")
			trackStroke.Thickness = 1
			trackStroke.Color = RX.Border
			trackStroke.Transparency = 1
			trackStroke.Parent = track

			local knob = Instance.new("Frame")
			knob.Size = UDim2.new(0, 18, 0, 18)
			knob.Position = UDim2.new(0, 2, 0.5, 0)
			knob.AnchorPoint = Vector2.new(0, 0.5)
			knob.BackgroundColor3 = Color3.fromRGB(150, 150, 170)
			knob.Parent = track

			local knobCorner = Instance.new("UICorner")
			knobCorner.CornerRadius = UDim.new(1, 0)
			knobCorner.Parent = knob

			local knobGlow = Instance.new("Frame")
			knobGlow.Size = UDim2.new(0.5, 0, 0.5, 0)
			knobGlow.Position = UDim2.new(0.25, 0, 0.25, 0)
			knobGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			knobGlow.BackgroundTransparency = 1
			knobGlow.BorderSizePixel = 0
			knobGlow.ZIndex = knob.ZIndex + 1
			knobGlow.Parent = knob

			local knobGlowCorner = Instance.new("UICorner")
			knobGlowCorner.CornerRadius = UDim.new(1, 0)
			knobGlowCorner.Parent = knobGlow

			local toggleBtn = Instance.new("TextButton")
			toggleBtn.Size = UDim2.new(1, 0, 1, 0)
			toggleBtn.BackgroundTransparency = 1
			toggleBtn.Text = ""
			toggleBtn.AutoButtonColor = false
			toggleBtn.ZIndex = track.ZIndex + 2
			toggleBtn.Parent = track

			local state = defaultState
			local locked = lockedState
			local isDebounced = false

			local knobOff = UDim2.new(0, 2, 0.5, 0)
			local knobOn = UDim2.new(0, 24, 0.5, 0)

			local function updateToggle(enabled, instant)
				local ti = instant and TweenInfo.new(0)
					or TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

				TweenService:Create(knob, ti, {
					Position = enabled and knobOn or knobOff,
					BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 170),
				}):Play()

				TweenService:Create(knobGlow, TWEEN_FAST, {
					BackgroundTransparency = enabled and 0.4 or 1,
				}):Play()

				TweenService:Create(track, TWEEN_NORMAL, {
					BackgroundColor3 = enabled and RX.Accent1 or Color3.fromRGB(38, 38, 55),
				}):Play()

				TweenService:Create(trackStroke, TWEEN_NORMAL, {
					Color = enabled and RX.Accent1 or RX.Border,
				}):Play()
			end

			local function updateLockedVisuals(instant)
				local tweenInfo = instant and TweenInfo.new(0) or TWEEN_FAST

				TweenService:Create(titleLabel, tweenInfo, {
					TextTransparency = locked and 0.35 or 0,
				}):Play()

				TweenService:Create(track, tweenInfo, {
					BackgroundTransparency = locked and 0.35 or 0,
				}):Play()

				TweenService:Create(knob, tweenInfo, {
					BackgroundTransparency = locked and 0.2 or 0,
				}):Play()
			end

			local function fireCallback()
				if typeof(callback) == "function" then
					task.spawn(function()
						callback(state)
					end)
				end
			end

			updateToggle(state, true)
			updateLockedVisuals(true)

			toggleBtn.Activated:Connect(function()
				if locked then
					return
				end

				if isDebounced then
					return
				end

				isDebounced = true

				state = not state
				updateToggle(state, false)
				fireCallback()

				task.delay(debounceTime, function()
					isDebounced = false
				end)
			end)

			return {
				Frame = frame,
				Button = toggleBtn,

				SetState = function(v, shouldCallback)
					state = v == true
					updateToggle(state, false)
					if shouldCallback == true then
						fireCallback()
					end
				end,

				GetState = function()
					return state
				end,

				SetLocked = function(v)
					locked = v == true
					updateLockedVisuals(false)
				end,

				GetLocked = function()
					return locked
				end,

				SetCallback = function(fn)
					callback = fn
				end,

				Destroy = function()
					if frame and frame.Parent then
						frame:Destroy()
					end
				end,
			}
		end

		return Tab
	end

	-- ════════════════════════════════════════════════════════
	-- WINDOW FUNCTIONS
	-- ════════════════════════════════════════════════════════

	function Window:Notify(config)
		ShowNotification(config)
	end

	function Window:Destroy()
		Window.StopPing()
		Window.StopFPS()
		if MainGui and MainGui.Parent then
			MainGui:Destroy()
		end
		cleanupOldInstances()
	end

	-- ════════════════════════════════════════════════════════
	-- START COUNTERS
	-- ════════════════════════════════════════════════════════

	Window.StartPing()
	Window.StartFPS()

	-- ════════════════════════════════════════════════════════
	-- VIEWPORT RESIZE HANDLER
	-- ════════════════════════════════════════════════════════

	local _lastVP = Vector2.new(0, 0)
	local _vpConnection = nil

	local function onViewportChanged()
		local vp = Camera.ViewportSize
		if math.abs(vp.X - _lastVP.X) < 2 and math.abs(vp.Y - _lastVP.Y) < 2 then
			return
		end
		_lastVP = vp
		if MainFrame and MainFrame.Parent then
			MainFrame.Position = getScreenCenter(MainFrame.AbsoluteSize.X, MainFrame.AbsoluteSize.Y)
		end
	end

	_vpConnection = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(onViewportChanged)
	MainGui.Destroying:Connect(function()
		if _vpConnection then
			_vpConnection:Disconnect()
			_vpConnection = nil
		end
	end)

	-- Initial sync
	task.spawn(function()
		local waited = 0
		while Camera.ViewportSize.X == 0 and waited < 3 do
			RunService.RenderStepped:Wait()
			waited = waited + 1 / 60
		end
		local syncLayout = calcLayout(Window.Width, Window.Height)
		MainFrame.Position = syncLayout.mainPos
		_lastVP = Camera.ViewportSize
	end)

	return Window
end

-- ═══════════════════════════════════════════════════════════
-- RETURN LIBRARY
-- ═══════════════════════════════════════════════════════════

return FlycerUI
