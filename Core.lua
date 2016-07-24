local SimplePointDisplay = LibStub("AceAddon-3.0"):NewAddon("SimplePointDisplay", "AceConsole-3.0", "AceEvent-3.0", "AceBucket-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local db

SimplePointDisplay.Types = {
	["GENERAL"] = {
		name = "General",
		points = {
			[1] = {name = "Combo Points", id = "cp", barcount = 5},
		},
	},
	["PALADIN"] = {
		name = "Paladin",
		points = {
			[1] = {name = "Holy Power", id = "hp", barcount = 5},
		},
	},
	["WARLOCK"] = {
		name = "Warlock",
		points = {
			[1] = {name = "Soul Shards", id = "ss", barcount = 5},
		},
	},
}
local Types = SimplePointDisplay.Types

---- Spell Info table
local SpellInfo = {
	["si"] = nil,
	["bs"] = nil,
	["lus"] = nil,
	["lac"] = nil,
	["al"] = nil,
	["rsa"] = nil,
	["fe"] = nil,
	["ab"] = nil,
	["ff"] = nil,
	["sz"] = nil,
	["vm"] = nil,
	["eva"] = nil,
	["deva"] = nil,
	["ser"] = nil,
	["bg"] = {[1] = nil, [2] = nil, [3] = nil},
	["ant"] = nil,
	["mw"] = nil,
	["ls"] = nil,
	["tw"] = nil,
	["ws"] = nil,
	["mco"] = nil,
	["ts"] = nil,
	["mc"] = nil,
	["sa"] = nil,
	["tb"] = nil,
}

---- Defaults
local defaults = {
	profile = {
		updatespeed = 8,
		classcolor = {
			enabled = false,
			bg = {
				empty = 0.15,
				normal = 0.7,
				max = 1,
			},
			border = {
				empty = 0,
				normal = 0,
				max = 0,
			},
			spark = {
				normal = 0.8,
				max = 1,
			},
		},
	-- CLASS/ID
		["*"] = {
			types = {
			-- Point Display type
				["*"] = {
					enabled = true,
					configmode = {
						enabled = false,
						count = 2,
					},
					general = {
						hideui = false,
						hideempty = false,
						hidein = {
							vehicle = false,
							spec = 1,
						},
						direction = {
							vertical = false,
							reverse = false,
						},
						showatzero = false,
					},
					position = {
						parent = "UIParent",
						anchorto = "CENTER",
						anchorfrom = "CENTER",
						x = 0,
						y = 0,
						framelevel = {
							strata = "MEDIUM",
							level = 2,
						},
					},
					bgpanel = {
						enabled = false,
						size = {
							width = 150,
							height = 12,
						},
						bg = {
							texture = "Solid",
							color = {r = 0.37, g = 0.37, b = 0.37, a = 1},
						},
						border = {
							texture = "Solid",
							edgesize = 1,
							inset = 0,
							color = {r = 0, g = 0, b = 0, a = 1},
						},
					},
					bars = {
						["*"] = {
							position = {
								gap = -1,
								xofs = 0,
								yofs = 0,
							},
							size = {
								width = 25,
								height = 8,
							},
							bg = {
								empty = {
									texture = "Solid",
									color = {r = 0.14, g = 0.14, b = 0.14, a = 1},
								},
								full = {
									texture = "Solid",
									color = {r = 0.7, g = 0.7, b = 0.7, a = 1},
									maxcolor = {r = 1, g = 1, b = 1, a = 1},
								},
							},
							border = {
								empty = {
									texture = "Solid",
									edgesize = 1,
									inset = 0,
									color = {r = 0, g = 0, b = 0, a = 1},
								},
								full = {
									texture = "Solid",
									edgesize = 1,
									inset = 0,
									color = {r = 0, g = 0, b = 0, a = 1},
									maxcolor = {r = 0, g = 0, b = 0, a = 1},
								},
							},
							spark = {
								enabled = false,
								position = {
									x = 0,
									y = 0,
								},
								size = {
									width = 32,
									height = 18,
								},
								bg = {
									texture = "",
									color = {r = 0.8, g = 0.8, b = 0.8, a = 1},
									maxcolor = {r = 1, g = 1, b = 1, a = 1},
								},
							},
						},
					},
					combatfader = {
						enabled = false,
						opacity = {
							incombat = 1,
							hurt = .7,
							target = .7,
							outofcombat = .3,
						},
					},
				},
			},
		},
	},
}

-- Point Display tables
local Frames = {}
local Borders = {}
local BG = {}

-- Points
local Points = {}
local PointsChanged = {}
local ClassColors
local ClassColorBarTable = {}

local LoggedIn = false
local PlayerClass
local PlayerSpec

local ValidClasses

-- Combat Fader
local CFFrame = CreateFrame("Frame")
local FadeTime = 0.25
local CFStatus = nil

-- Power 'Full' check
local power_check = {
	MANA = function()
		return UnitMana("player") < UnitManaMax("player")
	end,
	RAGE = function()
		return UnitMana("player") > 0
	end,
	ENERGY = function()
		return UnitMana("player") < UnitManaMax("player")
	end,
	RUNICPOWER = function()
		return UnitMana("player") > 0
	end,
}

-- Fade frame
local function FadeIt(self, NewOpacity)
	local CurrentOpacity = self:GetAlpha()
	if NewOpacity > CurrentOpacity then
		UIFrameFadeIn(self, FadeTime, CurrentOpacity, NewOpacity)
	elseif NewOpacity < CurrentOpacity then
		UIFrameFadeOut(self, FadeTime, CurrentOpacity, NewOpacity)
	end
end

-- Determine new opacity values for frames
function SimplePointDisplay:FadeFrames()
	for ic,vc in pairs(Types) do
		for it,vt in ipairs(Types[ic].points) do
			local NewOpacity
			local tid = Types[ic].points[it].id
			-- Retrieve opacity/visibility for current status
			NewOpacity = 1
			if db[ic].types[tid].combatfader.enabled then
				if CFStatus == "DISABLED" then
					NewOpacity = 1
				elseif CFStatus == "INCOMBAT" then
					NewOpacity = db[ic].types[tid].combatfader.opacity.incombat
				elseif CFStatus == "TARGET" then
					NewOpacity = db[ic].types[tid].combatfader.opacity.target
				elseif CFStatus == "HURT" then
					NewOpacity = db[ic].types[tid].combatfader.opacity.hurt
				elseif CFStatus == "OUTOFCOMBAT" then
					NewOpacity = db[ic].types[tid].combatfader.opacity.outofcombat
				end

				-- Fade Frame
				FadeIt(Frames[ic][tid].bgpanel.frame, NewOpacity)
			else
				-- Combat Fader disabled for this frame
				if Frames[ic][tid].bgpanel.frame:GetAlpha() < 1 then
					FadeIt(Frames[ic][tid].bgpanel.frame, NewOpacity)
				end
			end
		end
	end
	SimplePointDisplay:UpdatePointDisplay("ENABLE")
end

function SimplePointDisplay:UpdateCFStatus()
	local OldStatus = CFStatus

	-- Combat Fader based on status
	if UnitAffectingCombat("player") then
		CFStatus = "INCOMBAT"
	elseif UnitExists("target") then
		CFStatus = "TARGET"
	elseif UnitHealth("player") < UnitHealthMax("player") then
		CFStatus = "HURT"
	else
		local _, power_token = UnitPowerType("player")
		local func = power_check[power_token]
		if func and func() then
			CFStatus = "HURT"
		else
			CFStatus = "OUTOFCOMBAT"
		end
	end
	if CFStatus ~= OldStatus then SimplePointDisplay:FadeFrames() end
end

function SimplePointDisplay:UpdateCombatFader()
	CFStatus = nil
	SimplePointDisplay:UpdateCFStatus()
end

-- On combat state change
function SimplePointDisplay:CombatFaderCombatState()
	-- If in combat, then don't worry about health/power events
	if UnitAffectingCombat("player") then
		CFFrame:UnregisterEvent("UNIT_HEALTH")
		CFFrame:UnregisterEvent("UNIT_POWER")
		CFFrame:UnregisterEvent("UNIT_DISPLAYPOWER")
	else
		CFFrame:RegisterEvent("UNIT_HEALTH")
		CFFrame:RegisterEvent("UNIT_POWER")
		CFFrame:RegisterEvent("UNIT_DISPLAYPOWER")
	end
end

-- Register events for Combat Fader status
function SimplePointDisplay:UpdateCombatFaderEnabled()
	CFFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	CFFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	CFFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	CFFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

	CFFrame:SetScript("OnEvent", function(self, event, ...)
		if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
			SimplePointDisplay:CombatFaderCombatState()
			SimplePointDisplay:UpdateCFStatus()
		elseif event == "UNIT_HEALTH" or event == "UNIT_POWER" or event == "UNIT_DISPLAYPOWER" then
			local unit = ...
			if unit == "player" then
				SimplePointDisplay:UpdateCFStatus()
			end
		elseif event == "PLAYER_TARGET_CHANGED" then
			SimplePointDisplay:UpdateCFStatus()
		elseif event == "PLAYER_ENTERING_WORLD" then
			SimplePointDisplay:CombatFaderCombatState()
			SimplePointDisplay:UpdateCombatFader()
		end
	end)

	SimplePointDisplay:UpdateCombatFader()
	SimplePointDisplay:FadeFrames()
end

-- Update Point Bars
local function SetPointBarTextures(shown, ic, it, tid, i)
	-- Visible Bar
	if shown then
		-- BG
		Frames[ic][tid].bars[i].bg:SetTexture(BG[ic][tid].bars[i].full)

		-- Border
		Frames[ic][tid].bars[i].border:SetBackdrop({bgFile = "", edgeFile = Borders[ic][tid].bars[i].full, edgeSize = db[ic].types[tid].bars[i].border.full.edgesize, tile = false, tileSize = 0, insets = {left = 0, right = 0, top = 0, bottom = 0}})
		Frames[ic][tid].bars[i].border:SetHeight(db[ic].types[tid].bars[i].size.height - db[ic].types[tid].bars[i].border.full.inset)
		Frames[ic][tid].bars[i].border:SetWidth(db[ic].types[tid].bars[i].size.width - db[ic].types[tid].bars[i].border.full.inset)

		-- Colors
		if Points[tid] < Types[ic].points[it].barcount then
			if db.classcolor.enabled then
				Frames[ic][tid].bars[i].bg:SetVertexColor(ClassColorBarTable[ic].bg.normal.r, ClassColorBarTable[ic].bg.normal.g, ClassColorBarTable[ic].bg.normal.b, db[ic].types[tid].bars[i].bg.full.color.a)
				Frames[ic][tid].bars[i].border:SetBackdropBorderColor(ClassColorBarTable[ic].border.normal.r, ClassColorBarTable[ic].border.normal.g, ClassColorBarTable[ic].border.normal.b, db[ic].types[tid].bars[i].border.full.color.a)
			else
				Frames[ic][tid].bars[i].bg:SetVertexColor(db[ic].types[tid].bars[i].bg.full.color.r, db[ic].types[tid].bars[i].bg.full.color.g, db[ic].types[tid].bars[i].bg.full.color.b, db[ic].types[tid].bars[i].bg.full.color.a)
				Frames[ic][tid].bars[i].border:SetBackdropBorderColor(db[ic].types[tid].bars[i].border.full.color.r, db[ic].types[tid].bars[i].border.full.color.g, db[ic].types[tid].bars[i].border.full.color.b, db[ic].types[tid].bars[i].border.full.color.a)
			end
		else
			if db.classcolor.enabled then
				Frames[ic][tid].bars[i].bg:SetVertexColor(ClassColorBarTable[ic].bg.max.r, ClassColorBarTable[ic].bg.max.g, ClassColorBarTable[ic].bg.max.b, db[ic].types[tid].bars[i].bg.full.maxcolor.a)
				Frames[ic][tid].bars[i].border:SetBackdropBorderColor(ClassColorBarTable[ic].border.max.r, ClassColorBarTable[ic].border.max.g, ClassColorBarTable[ic].border.max.b, db[ic].types[tid].bars[i].bg.full.maxcolor.a)
			else
				Frames[ic][tid].bars[i].bg:SetVertexColor(db[ic].types[tid].bars[i].bg.full.maxcolor.r, db[ic].types[tid].bars[i].bg.full.maxcolor.g, db[ic].types[tid].bars[i].bg.full.maxcolor.b, db[ic].types[tid].bars[i].bg.full.maxcolor.a)
				Frames[ic][tid].bars[i].border:SetBackdropBorderColor(db[ic].types[tid].bars[i].border.full.maxcolor.r, db[ic].types[tid].bars[i].border.full.maxcolor.g, db[ic].types[tid].bars[i].border.full.maxcolor.b, db[ic].types[tid].bars[i].border.full.maxcolor.a)
			end
		end

		-- Spark
		if db[ic].types[tid].bars[i].spark.enabled then
			Frames[ic][tid].bars[i].spark.frame:Show()
			Frames[ic][tid].bars[i].spark.bg:SetTexture(BG[ic][tid].bars[i].spark)
			if Points[tid] < Types[ic].points[it].barcount then
				-- Normal color
				if db.classcolor.enabled then
					Frames[ic][tid].bars[i].spark.bg:SetVertexColor(ClassColorBarTable[ic].spark.normal.r, ClassColorBarTable[ic].spark.normal.g, ClassColorBarTable[ic].spark.normal.b, db[ic].types[tid].bars[i].spark.bg.color.a)
				else
					Frames[ic][tid].bars[i].spark.bg:SetVertexColor(db[ic].types[tid].bars[i].spark.bg.color.r, db[ic].types[tid].bars[i].spark.bg.color.g, db[ic].types[tid].bars[i].spark.bg.color.b, db[ic].types[tid].bars[i].spark.bg.color.a)
				end
			else
				-- Max color
				if db.classcolor.enabled then
					Frames[ic][tid].bars[i].spark.bg:SetVertexColor(ClassColorBarTable[ic].spark.max.r, ClassColorBarTable[ic].spark.max.g, ClassColorBarTable[ic].spark.max.b, db[ic].types[tid].bars[i].spark.bg.maxcolor.a)
				else
					Frames[ic][tid].bars[i].spark.bg:SetVertexColor(db[ic].types[tid].bars[i].spark.bg.maxcolor.r, db[ic].types[tid].bars[i].spark.bg.maxcolor.g, db[ic].types[tid].bars[i].spark.bg.maxcolor.b, db[ic].types[tid].bars[i].spark.bg.maxcolor.a)
				end
			end
		else
			Frames[ic][tid].bars[i].spark.frame:Hide()
		end
	-- Empty Bar
	else
		Frames[ic][tid].bars[i].bg:SetTexture(BG[ic][tid].bars[i].empty)
		Frames[ic][tid].bars[i].border:SetBackdrop({bgFile = "", edgeFile = Borders[ic][tid].bars[i].empty, edgeSize = db[ic].types[tid].bars[i].border.empty.edgesize, tile = false, tileSize = 0, insets = {left = 0, right = 0, top = 0, bottom = 0}})
		Frames[ic][tid].bars[i].border:SetHeight(db[ic].types[tid].bars[i].size.height - db[ic].types[tid].bars[i].border.empty.inset)
		Frames[ic][tid].bars[i].border:SetWidth(db[ic].types[tid].bars[i].size.width - db[ic].types[tid].bars[i].border.empty.inset)

		if db.classcolor.enabled then
			Frames[ic][tid].bars[i].bg:SetVertexColor(ClassColorBarTable[ic].bg.empty.r, ClassColorBarTable[ic].bg.empty.g, ClassColorBarTable[ic].bg.empty.b, db[ic].types[tid].bars[i].bg.empty.color.a)
			Frames[ic][tid].bars[i].border:SetBackdropBorderColor(ClassColorBarTable[ic].border.empty.r, ClassColorBarTable[ic].border.empty.g, ClassColorBarTable[ic].border.empty.b, db[ic].types[tid].bars[i].border.empty.color.a)
		else
			Frames[ic][tid].bars[i].bg:SetVertexColor(db[ic].types[tid].bars[i].bg.empty.color.r, db[ic].types[tid].bars[i].bg.empty.color.g, db[ic].types[tid].bars[i].bg.empty.color.b, db[ic].types[tid].bars[i].bg.empty.color.a)
			Frames[ic][tid].bars[i].border:SetBackdropBorderColor(db[ic].types[tid].bars[i].border.empty.color.r, db[ic].types[tid].bars[i].border.empty.color.g, db[ic].types[tid].bars[i].border.empty.color.b, db[ic].types[tid].bars[i].border.empty.color.a)
		end
	end
end

function SimplePointDisplay:UpdatePointDisplay(...)
	local UpdateList
	if ... == "ENABLE" then
		-- Update everything
		UpdateList = Types
	else
		UpdateList = ValidClasses
	end

	-- Cycle through all Types that need updating
	for ic,vc in pairs(UpdateList) do
		-- Cycle through all Point Displays in current Type
		for it,vt in ipairs(Types[ic].points) do
			local tid = Types[ic].points[it].id

			-- Do we hide the Display
			if ((Points[tid] == 0 and not db[ic].types[tid].general.showatzero)
				or (ic ~= PlayerClass and ic ~= "GENERAL") 	-- Not my class
				or ((PlayerClass ~= "ROGUE") and (ic == "GENERAL") and not UnitHasVehicleUI("player"))	-- Impossible to have Combo Points
				or (db[ic].types[tid].general.hidein.vehicle and UnitHasVehicleUI("player"))	-- Hide in vehicle
				or ((db[ic].types[tid].general.hidein.spec - 1) == PlayerSpec))	-- Hide in spec
				and not db[ic].types[tid].configmode.enabled then	-- Not in config mode
					-- Hide Display
					Frames[ic][tid].bgpanel.frame:Hide()
			else
			-- Update the Display
				-- Update Bars if their Points have changed
				if PointsChanged[tid] then
					for i = 1, Types[ic].points[it].barcount do
						if Points[tid] == nil then Points[tid] = 0 end
						if Points[tid] >= i then
						-- Show bar and set textures to "Full"
							Frames[ic][tid].bars[i].frame:Show()
							SetPointBarTextures(true, ic, it, tid, i)
						else
							if db[ic].types[tid].general.hideempty then
							-- Hide "empty" bar
								Frames[ic][tid].bars[i].frame:Hide()
							else
							-- Show bar and set textures to "Empty"
								Frames[ic][tid].bars[i].frame:Show()
								SetPointBarTextures(false, ic, it, tid, i)
							end
							-- Hide the "Spark"
							Frames[ic][tid].bars[i].spark.frame:Hide()
						end

					end
					-- Show the Display
					Frames[ic][tid].bgpanel.frame:Show()

					-- Flag as having been changed
					PointsChanged[tid] = false
				end
			end
		end
	end
end

-- Point retrieval
local function GetDebuffCount(SpellID, ...)
	if not SpellID then return end
	local unit = ... or "target"
	local _,_,_,count,_,_,_,caster = UnitDebuff(unit, SpellID)
	if ( (count == nil) or (caster ~= "player") ) then count = 0 end	-- Make sure Count isn't Nil, and only show Debuffs cast by me
	return count
end

local function GetBuffCount(SpellID, ...)
	if not SpellID then return end
	local unit = ... or "player"
	local _,_,_,count = UnitAura(unit, SpellID)
	if (count == nil) then count = 0 end
	return count
end

function SimplePointDisplay:GetPoints(CurClass, CurType)
	local NewPoints
	-- General
	if CurClass == "GENERAL" then
		-- Combo Points
		if CurType == "cp" then
			NewPoints = GetComboPoints(UnitHasVehicleUI("player") and "vehicle" or "player", "target")
		end
	-- Paladin
	elseif CurClass == "PALADIN" then
		-- Holy Power
		if CurType == "hp" then
			NewPoints = UnitPower("player", SPELL_POWER_HOLY_POWER)
		end
	-- Warlock
	elseif CurClass == "WARLOCK" then
		-- Soul Shards
		if CurType == "ss" then
			NewPoints = UnitPower("player", SPELL_POWER_SOUL_SHARDS)
		end
	end
	Points[CurType] = NewPoints
end

-- Update all valid Point Displays
function SimplePointDisplay:UpdatePoints(...)
	if not LoggedIn then return end

	local HasChanged = false
	local Enable = ...

	local UpdateList
	if ... == "ENABLE" then
		-- Update everything
		UpdateList = Types
	else
		UpdateList = ValidClasses
	end

	-- ENABLE update: Config Mode / Reset displays
	if Enable == "ENABLE" then
		HasChanged = true
		for ic,vc in pairs(Types) do
			for it,vt in ipairs(Types[ic].points) do
				local tid = Types[ic].points[it].id
				PointsChanged[tid] = true
				if ( db[ic].types[tid].enabled and db[ic].types[tid].configmode.enabled ) then
					-- If Enabled and Config Mode is on, then set points
					Points[tid] = db[ic].types[tid].configmode.count
				else
					Points[tid] = 0
				end
			end
		end
	end

	-- Normal update: Cycle through valid classes
	for ic,vc in pairs(UpdateList) do
		-- Cycle through point types for current class
		if Types[ic] then
			for it,vt in ipairs(Types[ic].points) do
				local tid = Types[ic].points[it].id
				if ( db[ic].types[tid].enabled and not db[ic].types[tid].configmode.enabled ) then
					-- Retrieve new point count
					local OldPoints = Points[tid]
					SimplePointDisplay:GetPoints(ic, tid)
					if Points[tid] ~= OldPoints then
						-- Points have changed, flag for updating
						HasChanged = true
						PointsChanged[tid] = true
					end
				end
			end
		end
	end

	-- Update Point Displays
	if HasChanged then SimplePointDisplay:UpdatePointDisplay(Enable) end
end

-- Enable a Point Display
function SimplePointDisplay:EnablePointDisplay(c, t)
	SimplePointDisplay:UpdatePoints("ENABLE")
end

-- Disable a Point Display
function SimplePointDisplay:DisablePointDisplay(c, t)
	-- Set to 0 points
	Points[t] = 0
	PointsChanged[t] = true

	-- Update Point Displays
	SimplePointDisplay:UpdatePointDisplay("ENABLE")
end

-- Update frame positions/sizes
function SimplePointDisplay:UpdatePosition()
	for ic,vc in pairs(Types) do
		for it,vt in ipairs(Types[ic].points) do
			local tid = Types[ic].points[it].id
			---- BG Panel
			local Parent = _G[db[ic].types[tid].position.parent]
			if not Parent then Parent = UIParent end

			Frames[ic][tid].bgpanel.frame:SetParent(Parent)
			Frames[ic][tid].bgpanel.frame:ClearAllPoints()
			Frames[ic][tid].bgpanel.frame:SetPoint(db[ic].types[tid].position.anchorfrom, Parent, db[ic].types[tid].position.anchorto, db[ic].types[tid].position.x, db[ic].types[tid].position.y)
			Frames[ic][tid].bgpanel.frame:SetFrameStrata(db[ic].types[tid].position.framelevel.strata)
			Frames[ic][tid].bgpanel.frame:SetFrameLevel(db[ic].types[tid].position.framelevel.level)
			Frames[ic][tid].bgpanel.frame:SetWidth(db[ic].types[tid].bgpanel.size.width)
			Frames[ic][tid].bgpanel.frame:SetHeight(db[ic].types[tid].bgpanel.size.height)

			Frames[ic][tid].bgpanel.border:SetFrameStrata(db[ic].types[tid].position.framelevel.strata)
			Frames[ic][tid].bgpanel.border:SetFrameLevel(db[ic].types[tid].position.framelevel.level + 1)
			Frames[ic][tid].bgpanel.border:SetHeight(db[ic].types[tid].bgpanel.size.height - db[ic].types[tid].bgpanel.border.inset)
			Frames[ic][tid].bgpanel.border:SetWidth(db[ic].types[tid].bgpanel.size.width - db[ic].types[tid].bgpanel.border.inset)

			---- Anchor
			Frames[ic][tid].anchor.frame:SetParent(Parent)
			Frames[ic][tid].anchor.frame:ClearAllPoints()
			Frames[ic][tid].anchor.frame:SetPoint(db[ic].types[tid].position.anchorfrom, Parent, db[ic].types[tid].position.anchorto, db[ic].types[tid].position.x, db[ic].types[tid].position.y)
			Frames[ic][tid].anchor.frame:SetFrameStrata(db[ic].types[tid].position.framelevel.strata)
			Frames[ic][tid].anchor.frame:SetFrameLevel(db[ic].types[tid].position.framelevel.level)
			Frames[ic][tid].anchor.frame:SetWidth(db[ic].types[tid].bgpanel.size.width)
			Frames[ic][tid].anchor.frame:SetHeight(db[ic].types[tid].bgpanel.size.height)

			---- Point Bars
			local IsVert, IsRev = db[ic].types[tid].general.direction.vertical, db[ic].types[tid].general.direction.reverse
			local XPos, YPos, CPRatio, TWidth, THeight
			local Positions = {}
			local CPSize = {}

			-- Get total Width and Height of Point Display, and the size of each Bar
			TWidth = 0
			THeight = 0
			for i = 1, Types[ic].points[it].barcount do
				if IsVert then
					CPSize[i] = db[ic].types[tid].bars[i].size.height + db[ic].types[tid].bars[i].position.gap
					THeight = THeight + db[ic].types[tid].bars[i].size.height + db[ic].types[tid].bars[i].position.gap
				else
					CPSize[i] = db[ic].types[tid].bars[i].size.width + db[ic].types[tid].bars[i].position.gap
					TWidth = TWidth + db[ic].types[tid].bars[i].size.width + db[ic].types[tid].bars[i].position.gap
				end
			end

			-- Calculate position of each Bar
			for i = 1, Types[ic].points[it].barcount do
				local CurPos = 0
				local TVal

				-- Get appropriate total to compare each Bar against
				if IsVert then
					TVal = THeight
				else
					TVal = TWidth
				end

				-- Add up position of each Bar in sequence
				if i == 1 then
					CurPos = (CPSize[i] / 2) - (TVal / 2)
				else
					for j = 1, i-1 do
						CurPos = CurPos + CPSize[j]
					end
					CurPos = CurPos + (CPSize[i] / 2) - (TVal / 2)
				end

				-- Found Position of Bar
				Positions[i] = CurPos
			end

			-- Position each Bar
			for i = 1, Types[ic].points[it].barcount do
				local XOfs = db[ic].types[tid].bars[i].position.xofs
				local YOfs = db[ic].types[tid].bars[i].position.yofs

				local RevMult = 1
				if IsRev then RevMult = -1 end

				Frames[ic][tid].bars[i].frame:SetParent(Frames[ic][tid].bgpanel.frame)
				Frames[ic][tid].bars[i].frame:ClearAllPoints()

				if IsVert then
					XPos = 0
					YPos = Positions[i] * RevMult
				else
					XPos = Positions[i] * RevMult
					YPos = 0
				end

				Frames[ic][tid].bars[i].frame:SetPoint("CENTER", Frames[ic][tid].bgpanel.frame, "CENTER", XPos + XOfs, YPos + YOfs)

				Frames[ic][tid].bars[i].frame:SetFrameStrata(db[ic].types[tid].position.framelevel.strata)
				Frames[ic][tid].bars[i].frame:SetFrameLevel(db[ic].types[tid].position.framelevel.level + 2)
				Frames[ic][tid].bars[i].frame:SetWidth(db[ic].types[tid].bars[i].size.width)
				Frames[ic][tid].bars[i].frame:SetHeight(db[ic].types[tid].bars[i].size.height)

				Frames[ic][tid].bars[i].border:SetFrameStrata(db[ic].types[tid].position.framelevel.strata)
				Frames[ic][tid].bars[i].border:SetFrameLevel(db[ic].types[tid].position.framelevel.level + 3)

				Frames[ic][tid].bars[i].spark.frame:SetParent(Frames[ic][tid].bars[i].frame)
				Frames[ic][tid].bars[i].spark.frame:ClearAllPoints()
				Frames[ic][tid].bars[i].spark.frame:SetPoint("CENTER", Frames[ic][tid].bars[i].frame, "CENTER", db[ic].types[tid].bars[i].spark.position.x, db[ic].types[tid].bars[i].spark.position.y)
				Frames[ic][tid].bars[i].spark.frame:SetFrameStrata(db[ic].types[tid].position.framelevel.strata)
				Frames[ic][tid].bars[i].spark.frame:SetFrameLevel(db[ic].types[tid].position.framelevel.level + 4)
				Frames[ic][tid].bars[i].spark.frame:SetWidth(db[ic].types[tid].bars[i].spark.size.width)
				Frames[ic][tid].bars[i].spark.frame:SetHeight(db[ic].types[tid].bars[i].spark.size.height)
			end
		end
	end
end

-- Update BG Panel textures
function SimplePointDisplay:UpdateBGPanelTextures()
	local BorderA
	local BGA

	for ic,vc in pairs(Types) do
		for it,vt in ipairs(Types[ic].points) do
			local tid = Types[ic].points[it].id
			-- Border
			if db[ic].types[tid].bgpanel.enabled then BorderA = db[ic].types[tid].bgpanel.border.color.a else BorderA = 0 end
			Frames[ic][tid].bgpanel.border:SetBackdrop({bgFile = "", edgeFile = Borders[ic][tid].bgpanel, edgeSize = db[ic].types[tid].bgpanel.border.edgesize, tile = false, tileSize = 0, insets = {left = 0, right = 0, top = 0, bottom = 0}})
			Frames[ic][tid].bgpanel.border:SetBackdropBorderColor(db[ic].types[tid].bgpanel.border.color.r, db[ic].types[tid].bgpanel.border.color.g, db[ic].types[tid].bgpanel.border.color.b, BorderA)

			-- BG
			if db[ic].types[tid].bgpanel.enabled then BGA = db[ic].types[tid].bgpanel.bg.color.a else BGA = 0 end
			Frames[ic][tid].bgpanel.bg:SetTexture(BG[ic][tid].bgpanel)
			Frames[ic][tid].bgpanel.bg:SetVertexColor(db[ic].types[tid].bgpanel.bg.color.r, db[ic].types[tid].bgpanel.bg.color.g, db[ic].types[tid].bgpanel.bg.color.b, BGA)
		end
	end
end

-- Retrieve SharedMedia backgound
local function RetrieveBackground(background)
	background = LSM:Fetch("background", background, true)
	return background
end

local function VerifyBackground(background)
	local newbackground = ""
	if background and strlen(background) > 0 then
		newbackground = RetrieveBackground(background)
		if background ~= "None" then
			if not newbackground then
				print("Background "..background.." was not found in SharedMedia.")
				newbackground = ""
			end
		end
	end
	return newbackground
end

-- Retrieve SharedMedia border
local function RetrieveBorder(border)
	border = LSM:Fetch("border", border, true)
	return border
end

local function VerifyBorder(border)
	local newborder = ""
	if border and strlen(border) > 0 then
		newborder = RetrieveBorder(border)
		if border ~= "None" then
			if not newborder then
				print("Border "..border.." was not found in SharedMedia.")
				newborder = ""
			end
		end
	end
	return newborder
end

-- Retrieve Border/Background textures and store in tables
function SimplePointDisplay:GetTextures()
	for ic,vc in pairs(Types) do
		for it,vt in ipairs(Types[ic].points) do
			local tid = Types[ic].points[it].id

			Borders[ic][tid].bgpanel = VerifyBorder(db[ic].types[tid].bgpanel.border.texture)
			BG[ic][tid].bgpanel = VerifyBackground(db[ic].types[tid].bgpanel.bg.texture)

			for i = 1, Types[ic].points[it].barcount do
				Borders[ic][tid].bars[i].empty = VerifyBorder(db[ic].types[tid].bars[i].border.empty.texture)
				Borders[ic][tid].bars[i].full = VerifyBorder(db[ic].types[tid].bars[i].border.full.texture)

				BG[ic][tid].bars[i].empty = VerifyBackground(db[ic].types[tid].bars[i].bg.empty.texture)
				BG[ic][tid].bars[i].full = VerifyBackground(db[ic].types[tid].bars[i].bg.full.texture)
				BG[ic][tid].bars[i].spark = VerifyBackground(db[ic].types[tid].bars[i].spark.bg.texture)
			end
		end
	end
end

function SimplePointDisplay:GetClassColors()
	local CurClassColor
	for k,v in pairs(Types) do
		tinsert(ClassColorBarTable, k)
		if k == "GENERAL" then
			CurClassColor = {r = 1, g = 1, b = 1}
		else
			CurClassColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[k] or RAID_CLASS_COLORS[k]
		end
		ClassColorBarTable[k] = {
			bg = {
				empty = {r = db.classcolor.bg.empty * CurClassColor.r, g = db.classcolor.bg.empty * CurClassColor.g, b = db.classcolor.bg.empty * CurClassColor.b},
				normal = {r = db.classcolor.bg.normal * CurClassColor.r, g = db.classcolor.bg.normal * CurClassColor.g, b = db.classcolor.bg.normal * CurClassColor.b},
				max = {r = db.classcolor.bg.max * CurClassColor.r, g = db.classcolor.bg.max * CurClassColor.g, b = db.classcolor.bg.max * CurClassColor.b},
			},
			border = {
				empty = {r = db.classcolor.border.empty * CurClassColor.r, g = db.classcolor.border.empty * CurClassColor.g, b = db.classcolor.border.empty * CurClassColor.b},
				normal = {r = db.classcolor.border.normal * CurClassColor.r, g = db.classcolor.border.normal * CurClassColor.g, b = db.classcolor.border.normal * CurClassColor.b},
				max = {r = db.classcolor.border.max * CurClassColor.r, g = db.classcolor.border.max * CurClassColor.g, b = db.classcolor.border.max * CurClassColor.b},
			},
			spark = {
				normal = {r = db.classcolor.spark.normal * CurClassColor.r, g = db.classcolor.spark.normal * CurClassColor.g, b = db.classcolor.spark.normal * CurClassColor.b},
				max = {r = db.classcolor.spark.max * CurClassColor.r, g = db.classcolor.spark.max * CurClassColor.g, b = db.classcolor.spark.max * CurClassColor.b},
			},
		}
	end
end

-- Frame Creation
local function CreateFrames()
	for ic,vc in pairs(Types) do
		for it,vt in ipairs(Types[ic].points) do
			local tid = Types[ic].points[it].id

			-- BG Panel
			local FrameName = "SimplePointDisplay_Frames_"..tid
			Frames[ic][tid].bgpanel.frame = CreateFrame("Frame", FrameName, UIParent)

			Frames[ic][tid].bgpanel.bg = Frames[ic][tid].bgpanel.frame:CreateTexture(nil, "ARTWORK")
			Frames[ic][tid].bgpanel.bg:SetAllPoints(Frames[ic][tid].bgpanel.frame)

			Frames[ic][tid].bgpanel.border = CreateFrame("Frame", nil, UIParent)
			Frames[ic][tid].bgpanel.border:SetParent(Frames[ic][tid].bgpanel.frame)
			Frames[ic][tid].bgpanel.border:ClearAllPoints()
			Frames[ic][tid].bgpanel.border:SetPoint("CENTER", Frames[ic][tid].bgpanel.frame, "CENTER", 0, 0)

			Frames[ic][tid].bgpanel.frame:Hide()

			-- Anchor Panel
			local AnchorFrameName = "SimplePointDisplay_Frames_"..tid.."_avAanchor"
			Frames[ic][tid].anchor.frame = CreateFrame("Frame", AnchorFrameName, UIParent)

			-- Point bars
			for i = 1, Types[ic].points[it].barcount do
				local BarFrameName = "SimplePointDisplay_Frames_"..tid.."_bar"..tostring(i)
				Frames[ic][tid].bars[i].frame = CreateFrame("Frame", BarFrameName, UIParent)

				Frames[ic][tid].bars[i].bg = Frames[ic][tid].bars[i].frame:CreateTexture(nil, "ARTWORK")
				Frames[ic][tid].bars[i].bg:SetAllPoints(Frames[ic][tid].bars[i].frame)

				Frames[ic][tid].bars[i].border = CreateFrame("Frame", nil, UIParent)
				Frames[ic][tid].bars[i].border:SetParent(Frames[ic][tid].bars[i].frame)
				Frames[ic][tid].bars[i].border:ClearAllPoints()
				Frames[ic][tid].bars[i].border:SetPoint("CENTER", Frames[ic][tid].bars[i].frame, "CENTER", 0, 0)

				Frames[ic][tid].bars[i].frame:Show()

				-- Spark
				Frames[ic][tid].bars[i].spark.frame = CreateFrame("Frame", nil, UIParent)

				Frames[ic][tid].bars[i].spark.bg = Frames[ic][tid].bars[i].spark.frame:CreateTexture(nil, "ARTWORK")
				Frames[ic][tid].bars[i].spark.bg:SetAllPoints(Frames[ic][tid].bars[i].spark.frame)

				Frames[ic][tid].bars[i].spark.frame:Show()
			end
		end
	end
end

-- Table creation
local function CreateTables()
	-- Frames
	wipe(Frames)
	wipe(Borders)
	wipe(BG)
	wipe(Points)
	wipe(PointsChanged)

	for ic,vc in pairs(Types) do
		-- Insert Class header
		tinsert(Frames, ic); Frames[ic] = {};
		tinsert(Borders, ic); Borders[ic] = {};
		tinsert(BG, ic); BG[ic] = {};

		for it,vt in ipairs(Types[ic].points) do
			local tid = Types[ic].points[it].id

			-- Frames
			tinsert(Frames[ic], tid)
			tinsert(Borders[ic], tid)
			tinsert(BG[ic], tid)

			Frames[ic][tid] = {
				anchor = {frame = nil},
				bgpanel = {frame = nil, bg = nil, border = nil},
				bars = {},
			}
			Borders[ic][tid] = {
				bgpanel = "",
				bars = {},
			}
			BG[ic][tid] = {
				bgpanel = "",
				bars = {},
			}
			for i = 1, Types[ic].points[it].barcount do
				Frames[ic][tid].bars[i] = {frame = nil, bg = nil, border = nil, spark = {frame = nil, bg = nil}}
				Borders[ic][tid].bars[i] = {empty = "", full = ""}
				BG[ic][tid].bars[i] = {empty = "", full = "", spark = ""}
			end

			-- Points
			Points[tid] = 0

			-- Points Changed table
			PointsChanged[tid] = false
		end
	end
end

function SimplePointDisplay:ProfChange()
	if not LoggedIn then return end

	db = self.db.profile
	SimplePointDisplay:ConfigRefresh()
	SimplePointDisplay:Refresh()
end

-- Refresh SimplePointDisplay
function SimplePointDisplay:Refresh()
	if not LoggedIn then return end

	SimplePointDisplay:UpdateSpec()
	SimplePointDisplay:UpdateCombatFaderEnabled()
	SimplePointDisplay:GetTextures()
	SimplePointDisplay:UpdateBGPanelTextures()
	SimplePointDisplay:UpdatePosition()
	SimplePointDisplay:UpdatePoints("ENABLE")
end

-- Hide default UI frames
function SimplePointDisplay:HideUIElements()
	if db["GENERAL"].types["cp"].enabled and db["GENERAL"].types["cp"].general.hideui then
		for i = 1,5 do
			_G["ComboPoint"..i]:Hide()
			_G["ComboPoint"..i]:SetScript("OnShow", function(self) self:Hide() end)
		end
	end

	if db["PALADIN"].types["hp"].enabled and db["PALADIN"].types["hp"].general.hideui then
		local HPF = _G["PaladinPowerBar"]
		if HPF then
			HPF:Hide()
			HPF:SetScript("OnShow", function(self) self:Hide() end)
		end
	end

	if db["WARLOCK"].types["ss"].enabled and db["WARLOCK"].types["ss"].general.hideui then
		local SSF = _G["ShardBarFrame"]
		if SSF then
			SSF:Hide()
			SSF:SetScript("OnShow", function(self) self:Hide() end)
		end
	end
end

function SimplePointDisplay:UpdateSpec()
	PlayerSpec = GetActiveSpecGroup()
end

function SimplePointDisplay:PLAYER_ENTERING_WORLD()
	SimplePointDisplay:UpdateSpec()
	SimplePointDisplay:UpdatePoints("ENABLE")
	SimplePointDisplay:UpdatePosition()
end

local function ClassColorsUpdate()
	ClassColors = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[PlayerClass] or RAID_CLASS_COLORS[PlayerClass]
	SimplePointDisplay:GetClassColors()
	SimplePointDisplay:UpdatePoints("ENABLE")
end

function SimplePointDisplay:PLAYER_LOGIN()
	PlayerClass = select(2, UnitClass("player"))

	-- Build Class list to run updates on
	ValidClasses = {
		["GENERAL"] = true,
		[PlayerClass] = true,
	},

	-- Register Media
	LSM:Register("border", "Solid", [[Interface\Addons\SimplePointDisplay\Media\SolidBorder]])
	LSM:Register("background", "Round-Small", [[Interface\Addons\SimplePointDisplay\Media\Round-Small]])
	LSM:Register("background", "Round-Smaller", [[Interface\Addons\SimplePointDisplay\Media\Round-Smaller]])
	LSM:Register("background", "Arrow", [[Interface\Addons\SimplePointDisplay\Media\Arrow]])
	LSM:Register("background", "Holy Power 1", [[Interface\Addons\SimplePointDisplay\Media\HolyPower1]])
	LSM:Register("background", "Holy Power 2", [[Interface\Addons\SimplePointDisplay\Media\HolyPower2]])
	LSM:Register("background", "Holy Power 3", [[Interface\Addons\SimplePointDisplay\Media\HolyPower3]])
	LSM:Register("background", "Soul Shard", [[Interface\Addons\SimplePointDisplay\Media\SoulShard]])

	-- Hide Elements
	SimplePointDisplay:HideUIElements()

	-- Register Events
	-- Throttled Events
	local EventList = {
		"UNIT_COMBO_POINTS",
		"VEHICLE_UPDATE",
		"UNIT_AURA",
	}
	if (PlayerClass == "PALADIN") then
		tinsert(EventList, "UNIT_POWER")
	end
	if (PlayerClass == "WARLOCK") then
		tinsert(EventList, "UNIT_POWER")
		tinsert(EventList, "UNIT_DISPLAYPOWER")
	end
	local UpdateSpeed = (1 / db.updatespeed)
	self:RegisterBucketEvent(EventList, UpdateSpeed, "UpdatePoints")
	-- Instant Events
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "UpdatePoints")

	-- Class Colors
	if CUSTOM_CLASS_COLORS then
		CUSTOM_CLASS_COLORS:RegisterCallback(ClassColorsUpdate)
	end
	ClassColorsUpdate()

	-- Flag as Logged In
	LoggedIn = true

	-- Refresh Addon
	SimplePointDisplay:Refresh()
end

function SimplePointDisplay:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("SimplePointDisplayDB", defaults, "Default")

	self.db.RegisterCallback(self, "OnProfileChanged", "ProfChange")
	self.db.RegisterCallback(self, "OnProfileCopied", "ProfChange")
	self.db.RegisterCallback(self, "OnProfileReset", "ProfChange")

	SimplePointDisplay:SetUpInitialOptions()

	db = self.db.profile

	CreateTables()
	CreateFrames()

	-- Turn off Config Mode
	for ic,vc in pairs(Types) do
		for it,vt in ipairs(Types[ic].points) do
			local tid = Types[ic].points[it].id
			db[ic].types[tid].configmode.enabled = false
		end
	end

	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "UpdateSpec")
end