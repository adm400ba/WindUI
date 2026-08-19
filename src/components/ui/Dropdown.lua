local DropdownMenu = {}
local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)
local UserInputService = cloneref(game:GetService("UserInputService"))
local Mouse = cloneref(game:GetService("Players")).LocalPlayer:GetMouse()
local Camera = cloneref(game:GetService("Workspace")).CurrentCamera
local CurrentCamera = workspace.CurrentCamera
local CreateInput = require("./Input").New
local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween
local TabBackgroundTransparency = 0.67
function DropdownMenu.New(Config, Dropdown, Element, Type)
	local DropdownModule = {}
	if not Dropdown.Callback then
		Type = "Menu"
	end
	Dropdown.UIElements.UIListLayout = New("UIListLayout", {
		Padding = UDim.new(0, Element.MenuPadding / 1.5),
		FillDirection = "Vertical",
		HorizontalAlignment = "Center",
	})
	Dropdown.UIElements.Menu = Creator.NewRoundFrame(Element.MenuCorner, "Squircle", {
		ThemeTag = {
			ImageColor3 = "DropdownBackground",
		},
		ImageTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
	}, {
		New("UIPadding", {
			PaddingTop = UDim.new(0, Element.MenuPadding),
			PaddingLeft = UDim.new(0, Element.MenuPadding),
			PaddingRight = UDim.new(0, Element.MenuPadding),
			PaddingBottom = UDim.new(0, Element.MenuPadding),
		}),
		New("UIListLayout", {
			FillDirection = "Vertical",
			Padding = UDim.new(0, Element.MenuPadding),
		}),
		New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, Dropdown.SearchBarEnabled and -Element.MenuPadding - Element.SearchBarHeight),
			ClipsDescendants = true,
			LayoutOrder = 999,
			Name = "Frame",
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Element.MenuCorner - Element.MenuPadding),
			}),
			New("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, 0),
				ScrollBarThickness = 0,
				ScrollingDirection = "Y",
				AutomaticCanvasSize = "None",
				CanvasSize = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				ScrollBarImageTransparency = 1,
			}, {
				Dropdown.UIElements.UIListLayout,
			}),
		}),
	})
	Dropdown.UIElements.MenuCanvas = New("Frame", {
		Size = UDim2.new(0, Dropdown.MenuWidth, 0, 300),
		BackgroundTransparency = 1,
		Position = UDim2.new(-10, 0, -10, 0),
		Visible = false,
		Active = false,
		Parent = Config.WindUI.DropdownGui,
		AnchorPoint = Vector2.new(1, 0),
	}, {
		Dropdown.UIElements.Menu,
		New("UISizeConstraint", {
			MinSize = Vector2.new(170, 0),
			MaxSize = Vector2.new(300, 400),
		}),
	})
	local function RecalculateCanvasSize()
		Dropdown.UIElements.Menu.Frame.ScrollingFrame.CanvasSize =
			UDim2.fromOffset(0, Dropdown.UIElements.UIListLayout.AbsoluteContentSize.Y)
	end
	local function RecalculateListSize()
		local MaxHeight = Config.WindUI.DropdownGui.AbsoluteSize.Y
		local ContentY = Dropdown.UIElements.UIListLayout.AbsoluteContentSize.Y / Config.UIScale
		local SearchBarOffset = Dropdown.SearchBarEnabled and (Element.SearchBarHeight + (Element.MenuPadding * 3))
			or (Element.MenuPadding * 2)
		local TotalY = ContentY + SearchBarOffset
		if TotalY > MaxHeight then
			Dropdown.UIElements.MenuCanvas.Size =
				UDim2.fromOffset(Dropdown.UIElements.MenuCanvas.AbsoluteSize.X, MaxHeight)
		else
			Dropdown.UIElements.MenuCanvas.Size =
				UDim2.fromOffset(Dropdown.UIElements.MenuCanvas.AbsoluteSize.X, TotalY)
		end
	end
	function UpdatePosition()
		local button = Dropdown.UIElements.Dropdown or Dropdown.DropdownFrame.UIElements.Main
		local menu = Dropdown.UIElements.MenuCanvas
		local availableSpaceBelow = Camera.ViewportSize.Y
			- (button.AbsolutePosition.Y + button.AbsoluteSize.Y)
			- Element.MenuPadding
			- 54
		local requiredSpace = menu.AbsoluteSize.Y + Element.MenuPadding
		local offset = -54
		if availableSpaceBelow < requiredSpace then
			offset = requiredSpace - availableSpaceBelow - 54
		end
		menu.Position = UDim2.new(
			0,
			button.AbsolutePosition.X + button.AbsoluteSize.X,
			0,
			button.AbsolutePosition.Y + button.AbsoluteSize.Y - offset + (Element.MenuPadding * 2)
		)
	end
	local SearchLabel
	function DropdownModule:Display()
		local Values = Dropdown.Values
		local Str = ""
		if Dropdown.Multi then
			local selected = {}
			local parts = {}
			if typeof(Dropdown.Value) == "table" then
				for _, item in ipairs(Dropdown.Value) do
					local title = typeof(item) == "table" and item.Title or item
					selected[title] = true
				end
			end
			for _, value in ipairs(Values) do
				local title = typeof(value) == "table" and value.Title or value
				if selected[title] then
					parts[#parts + 1] = tostring(title)
				end
			end
			Str = table.concat(parts, ", ")
		else
			Str = typeof(Dropdown.Value) == "table" and (Dropdown.Value.Title or Dropdown.Value[1])
				or Dropdown.Value
				or ""
		end
		if Dropdown.UIElements.Dropdown then
			Dropdown.UIElements.Dropdown.Frame.Frame.TextLabel.Text = Str
		end
	end
	local function Callback(customCallback, skipDisplay)
		if not skipDisplay then
			DropdownModule:Display()
		end
		if Dropdown.Locked then
			return
		end
		if Dropdown.Callback then
			task.spawn(function()
				if Dropdown.Locked then
					return
				end
				Creator.SafeCallback(Dropdown.Callback, Dropdown.Value)
			end)
		else
			task.spawn(function()
				if Dropdown.Locked then
					return
				end
				Creator.SafeCallback(customCallback)
			end)
		end
	end
	function DropdownModule:LockValues(lockedItems)
		if not lockedItems then
			return
		end
		for _, tab in next, Dropdown.Tabs do
			if tab and tab.UIElements and tab.UIElements.TabItem then
				local itemName = tab.Name
				local isLocked = false
				for _, lockedItem in next, lockedItems do
					if itemName == lockedItem then
						isLocked = true
						break
					end
				end
				if isLocked then
					Tween(tab.UIElements.TabItem, 0.1, { ImageTransparency = 1 }):Play()
					Tween(tab.UIElements.TabItem.Frame.Title.TextLabel, 0.1, { TextTransparency = 0.6 }):Play()
					if tab.UIElements.TabIcon then
						Tween(tab.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0.6 }):Play()
					end
					tab.UIElements.TabItem.Active = false
					tab.Locked = true
				else
					if tab.Selected then
						Tween(tab.UIElements.TabItem, 0.1, { ImageTransparency = TabBackgroundTransparency }):Play()
						Tween(tab.UIElements.TabItem.Frame.Title.TextLabel, 0.1, { TextTransparency = 0 }):Play()
						if tab.UIElements.TabIcon then
							Tween(tab.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0 }):Play()
						end
					else
						Tween(tab.UIElements.TabItem, 0.1, { ImageTransparency = 1 }):Play()
						Tween(
							tab.UIElements.TabItem.Frame.Title.TextLabel,
							0.1,
							{ TextTransparency = Type == "Dropdown" and 0.4 or 0.05 }
						):Play()
						if tab.UIElements.TabIcon then
							Tween(
								tab.UIElements.TabIcon.ImageLabel,
								0.1,
								{ ImageTransparency = Type == "Dropdown" and 0.2 or 0 }
							):Play()
						end
					end
					tab.UIElements.TabItem.Active = true
					tab.Locked = false
				end
			end
		end
	end
	function DropdownModule:Refresh(Values)
		if Config.Window.Destroyed then
			return
		end
		local ScrollingFrame = Dropdown.UIElements.Menu.Frame.ScrollingFrame
		local OldCache = Dropdown._RefreshCache or {}
		local NewCache = {}
		local KeepElements = {}
		local Occurrences = {}
		if Dropdown.SearchBarEnabled then
			if not SearchLabel then
				SearchLabel = CreateInput("Search...", "search", Dropdown.UIElements.Menu, nil, function(val)
					local search = string.lower(val)
					for _, tab in next, Dropdown.Tabs do
						if string.find(string.lower(tab.Name), search, 1, true) then
							tab.UIElements.TabItem.Visible = true
						else
							tab.UIElements.TabItem.Visible = false
						end
					end
					RecalculateListSize()
					RecalculateCanvasSize()
				end, true)
				SearchLabel.Size = UDim2.new(1, 0, 0, Element.SearchBarHeight)
				SearchLabel.Position = UDim2.new(0, 0, 0, 0)
				SearchLabel.Name = "SearchBar"
			end
		end
		Dropdown.Tabs = {}

		-- Remove duplicate visible options while preserving the first occurrence.
		-- Duplicate titles were previously assigned different cache keys, causing
		-- the same option to be rendered multiple times.
		local UniqueValues = {}
		local SeenValues = {}
		for _, Tab in ipairs(Values or {}) do
			local IsDivider = typeof(Tab) == "table" and Tab.Type == "Divider"
			if IsDivider then
				UniqueValues[#UniqueValues + 1] = Tab
			else
				local Title = typeof(Tab) == "table" and Tab.Title or Tab
				local Key = typeof(Title) .. "\0" .. tostring(Title or "")
				if not SeenValues[Key] then
					SeenValues[Key] = true
					UniqueValues[#UniqueValues + 1] = Tab
				end
			end
		end
		Values = UniqueValues

		local GetKey = function(Tab, IsDivider)
			local BaseName
			if IsDivider then
				BaseName = "__DIVIDER__"
			else
				BaseName = typeof(Tab) == "table" and Tab.Title or Tab
			end
			BaseName = tostring(BaseName or "")
			Occurrences[BaseName] = (Occurrences[BaseName] or 0) + 1
			return BaseName .. "\0" .. Occurrences[BaseName]
		end
		local UpdateTab = function(TabMain, Tab)
			local Name = typeof(Tab) == "table" and Tab.Title or Tab
			local Desc = typeof(Tab) == "table" and Tab.Desc or nil
			local Icon = typeof(Tab) == "table" and Tab.Icon or nil
			local IconSize = typeof(Tab) == "table" and Tab.IconSize or nil
			local Locked = typeof(Tab) == "table" and Tab.Locked or false
			local OldIcon = TabMain.Icon
			local OldIconSize = TabMain.IconSize
			local changed = TabMain.Name ~= Name or TabMain.Desc ~= Desc or OldIcon ~= Icon or OldIconSize ~= IconSize or TabMain.Locked ~= Locked
			TabMain.Name = Name
			TabMain.Desc = Desc
			TabMain.Original = Tab
			TabMain.Locked = Locked
			TabMain.IconSize = IconSize
			local TabItem = TabMain.UIElements.TabItem
			local TitleFrame = TabItem.Frame.Title
			local TitleLabel = TitleFrame.TextLabel
			local DescLabel = TitleFrame.Desc
			if changed or TabMain._NeedsLayoutUpdate then
				TitleLabel.Text = TabMain.Name
				DescLabel.Text = TabMain.Desc or ""
				DescLabel.Visible = TabMain.Desc and true or false
				TitleFrame.Size = UDim2.new(1, TabMain.UIElements.TabIcon and -Element.TabPadding - Element.TabIcon or 0, 0, 0)
			end
			if TabItem.LayoutOrder ~= (TabMain._RefreshIndex or 0) then
				TabItem.LayoutOrder = TabMain._RefreshIndex or 0
			end
			if OldIcon ~= Icon then
				if TabMain.UIElements.TabIcon then
					TabMain.UIElements.TabIcon:Destroy()
					TabMain.UIElements.TabIcon = nil
				end
				if Icon then
					local TabIcon = Creator.Image(Icon, Icon, 0, Config.Window.Folder, "Dropdown", true)
					TabIcon.Size = UDim2.new(0, IconSize or Element.TabIcon, 0, IconSize or Element.TabIcon)
					TabIcon.ImageLabel.ImageTransparency = Type == "Dropdown" and 0.2 or 0
					TabMain.UIElements.TabIcon = TabIcon
					TabIcon.Parent = TitleFrame.Parent
				end
			elseif TabMain.UIElements.TabIcon and OldIconSize ~= IconSize then
				TabMain.UIElements.TabIcon.Size = UDim2.new(0, IconSize or Element.TabIcon, 0, IconSize or Element.TabIcon)
			end
			TabMain.Icon = Icon
			TabMain._NeedsLayoutUpdate = false
		end
		local CreateTab = function(TabMain)
			local TabIcon
			if TabMain.Icon then
				TabIcon = Creator.Image(TabMain.Icon, TabMain.Icon, 0, Config.Window.Folder, "Dropdown", true)
				TabIcon.Size =
					UDim2.new(0, TabMain.IconSize or Element.TabIcon, 0, TabMain.IconSize or Element.TabIcon)
				TabIcon.ImageLabel.ImageTransparency = Type == "Dropdown" and 0.2 or 0
				TabMain.UIElements.TabIcon = TabIcon
			end
			TabMain.UIElements.TabItem = Creator.NewRoundFrame(
				Element.MenuCorner - Element.MenuPadding,
				"Squircle",
				{
					Size = UDim2.new(1, 0, 0, 36),
					AutomaticSize = TabMain.Desc and "Y",
					ImageTransparency = 1,
					Parent = ScrollingFrame,
					ThemeTag = {
						ImageColor3 = "DropdownTabBackground",
					},
					Active = not TabMain.Locked,
				},
				{
					Creator.NewRoundFrame(Element.MenuCorner - Element.MenuPadding, "Glass-1.4", {
						Size = UDim2.new(1, 0, 1, 0),
						ThemeTag = {
							ImageColor3 = "DropdownTabBorder",
						},
						ImageTransparency = 1,
						Name = "Highlight",
					}, {
					}),
					New("Frame", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
					}, {
						New("UIListLayout", {
							Padding = UDim.new(0, Element.TabPadding),
							FillDirection = "Horizontal",
							VerticalAlignment = "Center",
						}),
						New("UIPadding", {
							PaddingTop = UDim.new(0, Element.TabPadding),
							PaddingLeft = UDim.new(0, Element.TabPadding),
							PaddingRight = UDim.new(0, Element.TabPadding),
							PaddingBottom = UDim.new(0, Element.TabPadding),
						}),
						New("UICorner", {
							CornerRadius = UDim.new(0, Element.MenuCorner - Element.MenuPadding),
						}),
						TabIcon,
						New("Frame", {
							Size = UDim2.new(1, TabIcon and -Element.TabPadding - Element.TabIcon or 0, 0, 0),
							BackgroundTransparency = 1,
							AutomaticSize = "Y",
							Name = "Title",
						}, {
							New("TextLabel", {
								Text = TabMain.Name,
								TextXAlignment = "Left",
								FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
								ThemeTag = {
									TextColor3 = "Text",
									BackgroundColor3 = "Text",
								},
								TextSize = 15,
								BackgroundTransparency = 1,
								TextTransparency = Type == "Dropdown" and 0.4 or 0.05,
								LayoutOrder = 999,
								AutomaticSize = "Y",
								Size = UDim2.new(1, 0, 0, 0),
							}),
							New("TextLabel", {
								Text = TabMain.Desc or "",
								TextXAlignment = "Left",
								FontFace = Font.new(Creator.Font, Enum.FontWeight.Regular),
								ThemeTag = {
									TextColor3 = "Text",
									BackgroundColor3 = "Text",
								},
								TextSize = 15,
								BackgroundTransparency = 1,
								TextTransparency = Type == "Dropdown" and 0.6 or 0.35,
								LayoutOrder = 999,
								AutomaticSize = "Y",
								TextWrapped = true,
								Size = UDim2.new(1, 0, 0, 0),
								Visible = TabMain.Desc and true or false,
								Name = "Desc",
							}),
							New("UIListLayout", {
								Padding = UDim.new(0, Element.TabPadding / 3),
								FillDirection = "Vertical",
							}),
						}),
					}),
				},
				true
			)
			Creator.AddSignal(TabMain.UIElements.TabItem.MouseButton1Click, function()
				if Dropdown.Locked or TabMain.Locked then
					return
				end
				if Type == "Dropdown" then
					if Dropdown.Multi then
						if not TabMain.Selected then
							TabMain.Selected = true
							Tween(
								TabMain.UIElements.TabItem,
								0.1,
								{ ImageTransparency = TabBackgroundTransparency }
							):Play()
							Tween(TabMain.UIElements.TabItem.Frame.Title.TextLabel, 0.1, { TextTransparency = 0 }):Play()
							if TabMain.UIElements.TabIcon then
								Tween(TabMain.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0 }):Play()
							end
							table.insert(Dropdown.Value, TabMain.Original)
						else
							if not Dropdown.AllowNone and #Dropdown.Value == 1 then
								return
							end
							TabMain.Selected = false
							Tween(TabMain.UIElements.TabItem, 0.1, { ImageTransparency = 1 }):Play()
							Tween(TabMain.UIElements.TabItem.Frame.Title.TextLabel, 0.1, { TextTransparency = 0.4 }):Play()
							if TabMain.UIElements.TabIcon then
								Tween(TabMain.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0.2 }):Play()
							end
							for i, v in next, Dropdown.Value do
								if typeof(v) == "table" and (v.Title == TabMain.Name) or (v == TabMain.Name) then
									table.remove(Dropdown.Value, i)
									break
								end
							end
						end
					else
						for _, TabPisun in next, Dropdown.Tabs do
							Tween(TabPisun.UIElements.TabItem, 0.1, { ImageTransparency = 1 }):Play()
							Tween(
								TabPisun.UIElements.TabItem.Frame.Title.TextLabel,
								0.1,
								{ TextTransparency = 0.4 }
							):Play()
							if TabPisun.UIElements.TabIcon then
								Tween(TabPisun.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0.2 }):Play()
							end
							TabPisun.Selected = false
						end
						TabMain.Selected = true
						Tween(TabMain.UIElements.TabItem, 0.1, { ImageTransparency = TabBackgroundTransparency }):Play()
						Tween(TabMain.UIElements.TabItem.Frame.Title.TextLabel, 0.1, { TextTransparency = 0 }):Play()
						if TabMain.UIElements.TabIcon then
							Tween(TabMain.UIElements.TabIcon.ImageLabel, 0.1, { ImageTransparency = 0 }):Play()
						end
						Dropdown.Value = TabMain.Original
					end
					Callback()
				else
					Callback(TabMain.Original.Callback or function() end)
				end
			end)
			if Type == "Menu" then
				Creator.AddSignal(TabMain.UIElements.TabItem.MouseEnter, function()
					if TabMain.Locked then
						return
					end
					Tween(TabMain.UIElements.TabItem, 0.08, { ImageTransparency = TabBackgroundTransparency }):Play()
				end)
				Creator.AddSignal(TabMain.UIElements.TabItem.InputEnded, function()
					Tween(TabMain.UIElements.TabItem, 0.08, { ImageTransparency = 1 }):Play()
				end)
			end
		end
		local UpdateSelection = function(TabMain, SelectedMap)
			local selected
			if Dropdown.Multi then
				selected = SelectedMap[TabMain.Name] == true
			else
				local currentValue = typeof(Dropdown.Value) == "table" and Dropdown.Value.Title or Dropdown.Value
				selected = currentValue == TabMain.Name
			end
			local TabItem = TabMain.UIElements.TabItem
			local TitleLabel = TabItem.Frame.Title.TextLabel
			local IconLabel = TabMain.UIElements.TabIcon and TabMain.UIElements.TabIcon.ImageLabel
			local stateChanged = TabMain.Selected ~= selected or TabMain._LastLocked ~= TabMain.Locked
			TabMain.Selected = selected
			TabMain._LastLocked = TabMain.Locked
			if not stateChanged then
				return
			end
			TabItem.Active = not TabMain.Locked
			if TabMain.Locked then
				TabItem.ImageTransparency = 1
				TitleLabel.TextTransparency = 0.6
				if IconLabel then
					IconLabel.ImageTransparency = 0.6
				end
			elseif selected then
				TabItem.ImageTransparency = TabBackgroundTransparency
				TitleLabel.TextTransparency = 0
				if IconLabel then
					IconLabel.ImageTransparency = 0
				end
			else
				TabItem.ImageTransparency = 1
				TitleLabel.TextTransparency = Type == "Dropdown" and 0.4 or 0.05
				if IconLabel then
					IconLabel.ImageTransparency = Type == "Dropdown" and 0.2 or 0
				end
			end
		end
		local SelectedMap = {}
		if Dropdown.Multi and typeof(Dropdown.Value) == "table" then
			for _, item in ipairs(Dropdown.Value) do
				local itemName = typeof(item) == "table" and item.Title or item
				SelectedMap[itemName] = true
			end
		end
		if Dropdown.Multi and typeof(Dropdown.Value) == "string" then
			for _, i in next, Values do
				if typeof(i) == "table" then
					if i.Title == Dropdown.Value then
						Dropdown.Value = { i }
						break
					end
				elseif i == Dropdown.Value then
					Dropdown.Value = { Dropdown.Value }
					break
				end
			end
		end
		for Index, Tab in next, Values do
			local IsDivider = typeof(Tab) == "table" and Tab.Type == "Divider"
			local Key = GetKey(Tab, IsDivider)
			if not IsDivider then
				local TabMain = OldCache[Key]
				local IsNew = false
				if not TabMain or not TabMain.UIElements or not TabMain.UIElements.TabItem or not TabMain.UIElements.TabItem.Parent then
					TabMain = {
						Name = typeof(Tab) == "table" and Tab.Title or Tab,
						Desc = typeof(Tab) == "table" and Tab.Desc or nil,
						Icon = typeof(Tab) == "table" and Tab.Icon or nil,
						IconSize = typeof(Tab) == "table" and Tab.IconSize or nil,
						Original = Tab,
						Selected = false,
						Locked = typeof(Tab) == "table" and Tab.Locked or false,
						UIElements = {},
						_RefreshKey = Key,
						_RefreshIndex = Index,
					}
					IsNew = true
					CreateTab(TabMain)
				else
					TabMain._RefreshKey = Key
					TabMain._RefreshIndex = Index
					UpdateTab(TabMain, Tab)
				end
				TabMain._RefreshIndex = Index
				TabMain.Original = Tab
				if IsNew then
					UpdateTab(TabMain, Tab)
				end
				UpdateSelection(TabMain, SelectedMap)
				Dropdown.Tabs[Index] = TabMain
				NewCache[Key] = TabMain
				KeepElements[TabMain.UIElements.TabItem] = true
			end
		end
		for _, Elementt in next, ScrollingFrame:GetChildren() do
			if not Elementt:IsA("UIListLayout") and not KeepElements[Elementt] then
				Elementt:Destroy()
			end
		end
		Dropdown._RefreshCache = NewCache
		Dropdown.Values = Values
		local SearchValue
		if SearchLabel then
			pcall(function()
				SearchValue = SearchLabel.Text
			end)
		end
		if SearchValue and SearchValue ~= "" then
			local LowerSearch = string.lower(SearchValue)
			for _, tab in next, Dropdown.Tabs do
				local visible = string.find(string.lower(tab.Name), LowerSearch, 1, true) ~= nil
				if tab.UIElements.TabItem.Visible ~= visible then
					tab.UIElements.TabItem.Visible = visible
				end
			end
		else
			for _, tab in next, Dropdown.Tabs do
				if not tab.UIElements.TabItem.Visible then
					tab.UIElements.TabItem.Visible = true
				end
			end
		end
		Dropdown.UIElements.MenuCanvas.Size = UDim2.new(
			0,
			Dropdown.MenuWidth + 6 + 6 + 5 + 5 + 18 + 6 + 6,
			Dropdown.UIElements.MenuCanvas.Size.Y.Scale,
			Dropdown.UIElements.MenuCanvas.Size.Y.Offset
		)
		DropdownModule:Display()
		RecalculateCanvasSize()
		RecalculateListSize()
		Callback(nil, true)
	end
	DropdownModule:Refresh(Dropdown.Values)
	function DropdownModule:Select(Items)
		if Items then
			Dropdown.Value = Items
		else
			if Dropdown.Multi then
				Dropdown.Value = {}
			else
				Dropdown.Value = nil
			end
		end
		DropdownModule:Refresh(Dropdown.Values)
	end
	RecalculateListSize()
	RecalculateCanvasSize()
	function DropdownModule:Open()
		if not Dropdown.Locked then
			Dropdown.UIElements.Menu.Visible = true
			Dropdown.UIElements.MenuCanvas.Visible = true
			Dropdown.UIElements.MenuCanvas.Active = true
			Dropdown.UIElements.Menu.Size = UDim2.new(1, 0, 0, 0)
			Tween(Dropdown.UIElements.Menu, 0.1, {
				Size = UDim2.new(1, 0, 1, 0),
				ImageTransparency = 0,
			}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()
			task.spawn(function()
				task.wait(0.1)
				if Dropdown.Locked then
					return
				end
				Dropdown.Opened = true
			end)
			UpdatePosition()
		end
	end
	function DropdownModule:Close()
		Dropdown.Opened = false
		Tween(Dropdown.UIElements.Menu, 0.25, {
			Size = UDim2.new(1, 0, 0, 0),
			ImageTransparency = 1,
		}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()
		task.spawn(function()
			task.wait(0.1)
			Dropdown.UIElements.Menu.Visible = false
		end)
		task.spawn(function()
			task.wait(0.25)
			Dropdown.UIElements.MenuCanvas.Visible = false
			Dropdown.UIElements.MenuCanvas.Active = false
		end)
	end
	Creator.AddSignal(
		(
			Dropdown.UIElements.Dropdown and Dropdown.UIElements.Dropdown.MouseButton1Click
			or Dropdown.DropdownFrame.UIElements.Main.MouseButton1Click
		),
		function()
			DropdownModule:Open()
		end
	)
	Creator.AddSignal(UserInputService.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			local menuCanvas = Dropdown.UIElements.MenuCanvas
			local AbsPos, AbsSize = menuCanvas.AbsolutePosition, menuCanvas.AbsoluteSize
			local DropdownButton = Dropdown.UIElements.Dropdown or Dropdown.DropdownFrame.UIElements.Main
			local ButtonAbsPos = DropdownButton.AbsolutePosition
			local ButtonAbsSize = DropdownButton.AbsoluteSize
			local isClickOnDropdown = Mouse.X >= ButtonAbsPos.X
				and Mouse.X <= ButtonAbsPos.X + ButtonAbsSize.X
				and Mouse.Y >= ButtonAbsPos.Y
				and Mouse.Y <= ButtonAbsPos.Y + ButtonAbsSize.Y
			local isClickOnMenu = Mouse.X >= AbsPos.X
				and Mouse.X <= AbsPos.X + AbsSize.X
				and Mouse.Y >= AbsPos.Y
				and Mouse.Y <= AbsPos.Y + AbsSize.Y
			if Config.Window.CanDropdown and Dropdown.Opened and not isClickOnDropdown and not isClickOnMenu then
				DropdownModule:Close()
			end
		end
	end)
	Creator.AddSignal(
		Dropdown.UIElements.Dropdown and Dropdown.UIElements.Dropdown:GetPropertyChangedSignal("AbsolutePosition")
			or Dropdown.DropdownFrame.UIElements.Main:GetPropertyChangedSignal("AbsolutePosition"),
		UpdatePosition
	)
	return DropdownModule
end
return DropdownMenu
