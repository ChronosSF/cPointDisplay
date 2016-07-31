local cPointDisplay = LibStub("AceAddon-3.0"):GetAddon("cPointDisplay")
local db

local Types = cPointDisplay.Types

local table_AnchorPoints = {
	"BOTTOM",
	"BOTTOMLEFT",
	"BOTTOMRIGHT",
	"CENTER",
	"LEFT",
	"RIGHT",
	"TOP",
	"TOPLEFT",
	"TOPRIGHT",
}

local table_Orientation = {
	"Horizontal",
	"Vertical",
}

local table_Strata = {
	"BACKGROUND",
	"LOW",
	"MEDIUM",
	"HIGH",
	"DIALOG",
	"TOOLTIP",
}

local table_Specs = {
	"None",
	"Primary",
	"Secondary",
}

local function ValidateOffset(value)
	val = tonumber(value)
	if val == nil then val = 0 end
	if val < -5000 then val = 5000 elseif val > 5000 then val = 5000 end
	return val
end

-- Return the Options table
local options = nil
local function GetOptions()
	if not options then
		options = {
			name = "cPointDisplay",
			handler = cPointDisplay,
			type = "group",
			args = {
				globalsettings = {
					name = "Global Settings",
					type = "group",
					order = 10,
					args = {
						updatespeed = {
							type = "range",
							name = "Update Speed (r/sec)",
							desc = "Throttle the Point Display updates to X times a second.\n\nHigher = faster updates, but more CPU usage.\n\nRequires a UI Reload (/rl) to take effect.",
							min = 1, max = 30, step = 1,
							get = function(info) return db.updatespeed end,
							set = function(info, value) db.updatespeed = value end,
							order = 10,
						},
						sep = {
							type = "description",
							name = " ",
							order = 20,
						},
						useclasscolor = {
							type = "toggle",
							name = "Class Color Override",
							desc = "Use Class Colors for Point Displays.",
							get = function() return db.classcolor.enabled end,
							set = function(info, value) 
								db.classcolor.enabled = value
								cPointDisplay:UpdatePoints("ENABLE")
							end,
							order = 30,
						},
						classcolor = {
							name = "Class Color settings",
							type = "group",
							inline = true,
							disabled = function() if not db.classcolor.enabled then return true end end,
							order = 40,
							args = {
								bg = {
									name = "Background",
									type = "group",
									inline = true,
									order = 10,
									args = {
										empty = {
											type = "range",
											name = "Empty",
											desc = "How bright/dark to make the Bar backgrounds when empty. 0 = Black, 1 = Unaltered Class Color.",
											min = 0, max = 1, step = 0.05,
											isPercent = true,
											get = function(info) return db.classcolor.bg.empty end,
											set = function(info, value)
												db.classcolor.bg.empty = value
												cPointDisplay:GetClassColors()
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											order = 10,
										},
										normal = {
											type = "range",
											name = "Normal",
											desc = "How bright/dark to make the normal Bar backgrounds. 0 = Black, 1 = Unaltered Class Color.",
											min = 0, max = 1, step = 0.05,
											isPercent = true,
											get = function(info) return db.classcolor.bg.normal end,
											set = function(info, value)
												db.classcolor.bg.normal = value
												cPointDisplay:GetClassColors()
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											order = 20,
										},
										max = {
											type = "range",
											name = "Full",
											desc = "How bright/dark to make the Bar backgrounds when you have reached full stacks. 0 = Black, 1 = Unaltered Class Color.",
											min = 0, max = 1, step = 0.05,
											isPercent = true,
											get = function(info) return db.classcolor.bg.max end,
											set = function(info, value)
												db.classcolor.bg.max = value
												cPointDisplay:GetClassColors()
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											order = 30,
										},
									},
								},
								border = {
									name = "Border",
									type = "group",
									inline = true,
									order = 20,
									args = {
										empty = {
											type = "range",
											name = "Empty",
											desc = "How bright/dark to make the Bar borders when empty. 0 = Black, 1 = Unaltered Class Color.",
											min = 0, max = 1, step = 0.05,
											isPercent = true,
											get = function(info) return db.classcolor.border.empty end,
											set = function(info, value)
												db.classcolor.border.empty = value
												cPointDisplay:GetClassColors()
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											order = 10,
										},
										normal = {
											type = "range",
											name = "Normal",
											desc = "How bright/dark to make the normal Bar borders. 0 = Black, 1 = Unaltered Class Color.",
											min = 0, max = 1, step = 0.05,
											isPercent = true,
											get = function(info) return db.classcolor.border.normal end,
											set = function(info, value)
												db.classcolor.border.normal = value
												cPointDisplay:GetClassColors()
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											order = 20,
										},
										max = {
											type = "range",
											name = "Full",
											desc = "How bright/dark to make the Bar borders when you have reached full stacks. 0 = Black, 1 = Unaltered Class Color.",
											min = 0, max = 1, step = 0.05,
											isPercent = true,
											get = function(info) return db.classcolor.border.max end,
											set = function(info, value)
												db.classcolor.border.max = value
												cPointDisplay:GetClassColors()
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											order = 30,
										},
									},
								},
								spark = {
									name = "Spark",
									type = "group",
									inline = true,
									order = 30,
									args = {
										normal = {
											type = "range",
											name = "Normal",
											desc = "How bright/dark to make the normal Bar spark. 0 = Black, 1 = Unaltered Class Color.",
											min = 0, max = 1, step = 0.05,
											isPercent = true,
											get = function(info) return db.classcolor.spark.normal end,
											set = function(info, value)
												db.classcolor.spark.normal = value
												cPointDisplay:GetClassColors()
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											order = 10,
										},
										max = {
											type = "range",
											name = "Full",
											desc = "How bright/dark to make the Bar spark when you have reached full stacks. 0 = Black, 1 = Unaltered Class Color.",
											min = 0, max = 1, step = 0.05,
											isPercent = true,
											get = function(info) return db.classcolor.spark.max end,
											set = function(info, value) 
												db.classcolor.spark.max = value
												cPointDisplay:GetClassColors()
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											order = 20,
										},
									},
								},
							},
						},
					},
				},
			},
		}
	end
	
	-- Create Copy All table
	local CopyAllFromTable = {}
	local CopyAllFromTableShort = {}
	local cnt = 1
	for ic,vc in pairs(Types) do
		for it,vt in ipairs(Types[ic].points) do
			local tid = Types[ic].points[it].id	
			
			tinsert(CopyAllFromTable, cnt)
			tinsert(CopyAllFromTableShort, cnt)
			CopyAllFromTable[cnt] = {
				name = Types[ic].points[it].name,
				class = ic,
				typeid = tid,
				typenum = it,
			}
			CopyAllFromTableShort[cnt] = Types[ic].points[it].name
			
			cnt = cnt + 1
		end		
	end
	
	local ClassOpts, TypeOpts, BarOpts, TrinketOpts = {}, {}, {}, {}
	local Opts_ClassOrderCnt = 40
	local Opts_TypeOrderCnt = 10
	
	for ic,vc in pairs(Types) do
		local ClassID = Types[ic].name
		
		wipe(TypeOpts)
		for it,vt in ipairs(Types[ic].points) do
			local tid = Types[ic].points[it].id			
			local TypeDesc = Types[ic].points[it].name
			
			TypeOpts[tid] = {
				type = "group",
				name = TypeDesc,
				childGroups = "tab",
				order = Opts_TypeOrderCnt,
				args = {
					header = {
						type = "header",
						name = string.format("%s - %s", ClassID, TypeDesc),
						order = 10,
					},
					enabled = {
						type = "toggle",
						name = "Enabled",
						desc = string.format("Enable/Disable the %s display.", TypeDesc),
						get = function() return db[ic].types[tid].enabled end,
						set = function(info, value) 
							db[ic].types[tid].enabled = value
							db[ic].types[tid].configmode.enabled = false
							if not value then
								cPointDisplay:DisablePointDisplay(ic, tid)
							else
								cPointDisplay:EnablePointDisplay(ic, tid)
							end
						end,
						order = 20,
					},
					sep = {
						type = "description",
						name = " ",
						order = 23,
					},
					copy = {
						type = "select",
						name = "Copy settings from",
						desc = "Copy all settings from another Point Display to this one.",
						set = function(info, value)
							local FromIC = CopyAllFromTable[value].class
							local FromTID = CopyAllFromTable[value].typeid
							local FromNum = CopyAllFromTable[value].typenum
							if FromTID ~= tid then
								cPointDisplay:CopyAllSettings(db[FromIC].types[FromTID], db[ic].types[tid], FromIC, ic, FromTID, tid, FromNum, it)
								cPointDisplay:GetTextures()
								cPointDisplay:UpdateBGPanelTextures()
								cPointDisplay:UpdatePosition()
								cPointDisplay:UpdatePoints("ENABLE")
							end
						end,
						style = "dropdown",
						width = nil,
						values = CopyAllFromTableShort,
						disabled = function() if db[ic].types[tid].enabled then return false else return true end end,
						order = 24,
					},
					config = {
						name = "Configuration",
						type = "group",
						order = 30,
						disabled = function() if db[ic].types[tid].enabled then return false else return true end end,
						args = {
							configmode = {
								type = "toggle",
								name = "Configuration Mode",
								get = function(info) return db[ic].types[tid].configmode.enabled end,
								set = function(info, value) 
									db[ic].types[tid].configmode.enabled = value
									cPointDisplay:UpdatePoints("ENABLE")
								end,
								order = 10,
							},
							configmodecount = {
								type = "range",
								name = "Config Mode point count",
								min = 0, max = Types[ic].points[it].barcount, step = 1,
								get = function(info) return db[ic].types[tid].configmode.count end,
								set = function(info, value) 
									db[ic].types[tid].configmode.count = value
									cPointDisplay:UpdatePoints("ENABLE")
								end,
								disabled = function() if db[ic].types[tid].configmode.enabled and db[ic].types[tid].enabled then return false else return true end end,
								order = 20,
							},
						},
					},				
					general = {
						name = "General Settings",
						type = "group",
						order = 70,
						disabled = function() if db[ic].types[tid].enabled then return false else return true end end,
						args = {
							appearance = {
								name = "Appearance",
								type = "group",
								order = 10,
								inline = true,
								args = {
									hideui = {
										type = "toggle",
										name = "Hide default UI display",
										desc = "Note: A UI reload (/reload ui) is required to make the default UI display visible again if you have it hidden.",
										width = "full",
										get = function(info) return db[ic].types[tid].general.hideui end,
										set = function(info, value) 
											db[ic].types[tid].general.hideui = value
											cPointDisplay:HideUIElements()
										end,
										order = 10,
										disabled = function() if (tid == "cp" or tid == "hp" or tid == "ss" or tid == "ac") then return false else return true end end,
									},
									showatzero = {
										type = "toggle",
										name = "Show at 0 points/stacks",
										desc = "Keep the bar visible even when there are no points/stacks.",
										width = "full",
										get = function(info) return db[ic].types[tid].general.showatzero end,
										set = function(info, value) 
											db[ic].types[tid].general.showatzero = value
											cPointDisplay:UpdatePoints("ENABLE")
										end,
										order = 10,
									},
									hideempty = {
										type = "toggle",
										name = "Hide unused points/stacks",
										desc = "Only show used the number of points/stacks you have. IE. If you have 4 Combo Points, the 5th Combo Point bar will remain hidden.",
										width = "full",
										get = function(info) return db[ic].types[tid].general.hideempty end,
										set = function(info, value) 
											db[ic].types[tid].general.hideempty = value
											cPointDisplay:UpdatePoints("ENABLE")
										end,
										order = 20,
									},
									hidein = {
										type = "group",
										name = "Hide in",
										inline = true,
										order = 30,
										args = {
											vehicle = {
												type = "toggle",
												name = "Vehicle",
												desc = "Hide when in a Vehicle.",
												width = "full",
												get = function(info) return db[ic].types[tid].general.hidein.vehicle end,
												set = function(info, value) 
													db[ic].types[tid].general.hidein.vehicle = value
													cPointDisplay:UpdatePoints("ENABLE")
												end,
												order = 10,
											},
											spec = {
												type = "select",
												name = "Spec",
												get = function(info)
													return db[ic].types[tid].general.hidein.spec
												end,
												set = function(info, value)
													db[ic].types[tid].general.hidein.spec = value
													cPointDisplay:UpdatePoints("ENABLE")
												end,
												style = "dropdown",
												width = nil,
												values = table_Specs,
												order = 30,
											},
										},
									},
									direction = {
										type = "group",
										name = "Direction",
										inline = true,
										order = 40,
										args = {
											vertical = {
												type = "toggle",
												name = "Vertical",
												desc = string.format("Orientate the %s display vertically.", TypeDesc),
												width = "full",
												get = function(info) return db[ic].types[tid].general.direction.vertical end,
												set = function(info, value) 
													db[ic].types[tid].general.direction.vertical = value
													cPointDisplay:UpdatePosition()
												end,
												order = 10,
											},
											reverse = {
												type = "toggle",
												name = "Reverse orientation",
												desc = string.format("Reverse the orientation of the %s display.", TypeDesc),
												width = "full",
												get = function(info) return db[ic].types[tid].general.direction.reverse end,
												set = function(info, value) 
													db[ic].types[tid].general.direction.reverse = value
													cPointDisplay:UpdatePosition()
												end,
												order = 20,
											},
										},
									},									
								},
							},
						},
					},
					position = {
						type = "group",
						name = "Position",
						order = 80,
						disabled = function() if db[ic].types[tid].enabled then return false else return true end end,
						args = {
							position = {
								name = "Position",
								type = "group",
								inline = true,
								order = 20,
								args = {
									xoffset = {
										type = "input",
										name = "X Offset",
										width = "half",
										order = 10,
										get = function(info) return tostring(db[ic].types[tid].position.x) end,
										set = function(info, value)
											value = ValidateOffset(value)
											db[ic].types[tid].position.x = value
											cPointDisplay:UpdatePosition()
										end,
									},
									yoffset = {
										type = "input",
										name = "Y Offset",
										width = "half",
										order = 20,
										get = function(info) return tostring(db[ic].types[tid].position.y) end,
										set = function(info, value)
											value = ValidateOffset(value)
											db[ic].types[tid].position.y = value
											cPointDisplay:UpdatePosition()
										end,
									},
									anchorto = {
										type = "select",
										name = "Anchor To",
										get = function(info) 
											for k,v in pairs(table_AnchorPoints) do
												if v == db[ic].types[tid].position.anchorto then return k end
											end
										end,
										set = function(info, value)
											db[ic].types[tid].position.anchorto = table_AnchorPoints[value]
											cPointDisplay:UpdatePosition()
										end,
										style = "dropdown",
										width = nil,
										values = table_AnchorPoints,
										order = 30,
									},
									anchorfrom = {
										type = "select",
										name = "Anchor From",
										get = function(info) 
											for k,v in pairs(table_AnchorPoints) do
												if v == db[ic].types[tid].position.anchorfrom then return k end
											end
										end,
										set = function(info, value)
											db[ic].types[tid].position.anchorfrom = table_AnchorPoints[value]
											cPointDisplay:UpdatePosition()
										end,
										style = "dropdown",
										width = nil,
										values = table_AnchorPoints,
										order = 40,
									},
									parent = {
										type = "input",
										name = "Parent",
										desc = string.format("Frame name to parent the %s display to.", TypeDesc),
										width = "half",
										order = 50,
										get = function(info) return tostring(db[ic].types[tid].position.parent) end,
										set = function(info, value)
											db[ic].types[tid].position.parent = value
											cPointDisplay:UpdatePosition()
										end,
									},
								},
							},
							framelevel = {
								type = "group",
								name = "Strata",
								inline = true,
								order = 30,
								args = {
									strata = {
										type = "select",
										name = "Strata",
										get = function(info) 
											for k,v in pairs(table_Strata) do
												if v == db[ic].types[tid].position.framelevel.strata then return k end
											end
										end,
										set = function(info, value)
											db[ic].types[tid].position.framelevel.strata = table_Strata[value]
											cPointDisplay:UpdatePosition()
										end,
										style = "dropdown",
										width = nil,
										values = table_Strata,
										order = 10,
									},
									level = {
										type = "range",
										name = "Frame Level",
										min = 1, max = 50, step = 1,
										get = function(info) return db[ic].types[tid].position.framelevel.level end,
										set = function(info, value) 
											db[ic].types[tid].position.framelevel.level = value
											cPointDisplay:UpdatePosition()
										end,
										order = 20,
									},
								},
							},
						},
					},
					bars = {
						name = "Point Bars",
						type = "group",
						childGroups = "tab",
						order = 90,
						disabled = function() if db[ic].types[tid].enabled then return false else return true end end,					
						args = {
						},
					},
					bgpanel = {
						name = "Background Panel",
						type = "group",
						childGroups = "tab",
						order = 100,
						disabled = function() if db[ic].types[tid].enabled then return false else return true end end,
						args = {
							enabled = {
								type = "toggle",
								name = "Enabled",
								desc = "Enable/Disable the Background Panel.",
								get = function(info) return db[ic].types[tid].bgpanel.enabled end,
								set = function(info, value) db[ic].types[tid].bgpanel.enabled = value cPointDisplay:UpdateBGPanelTextures() end,
								order = 10,
							},
							size = {
								type = "group",
								name = "Size",
								disabled = function() if db[ic].types[tid].bgpanel.enabled then return false else return true end end,
								order = 20,
								args = {
									width = {
										type = "input",
										name = "Width",
										width = "half",
										order = 10,
										get = function(info) return tostring(db[ic].types[tid].bgpanel.size.width) end,
										set = function(info, value)
											value = ValidateOffset(value)
											db[ic].types[tid].bgpanel.size.width = value
											cPointDisplay:UpdatePosition()
										end,
									},
									height = {
										type = "input",
										name = "Height",
										width = "half",
										order = 20,
										get = function(info) return tostring(db[ic].types[tid].bgpanel.size.height) end,
										set = function(info, value)
											value = ValidateOffset(value)
											db[ic].types[tid].bgpanel.size.height = value
											cPointDisplay:UpdatePosition()
										end,
									},
								},							
							},
							background = {
								name = "Background",
								type = "group",
								disabled = function() if db[ic].types[tid].bgpanel.enabled then return false else return true end end,
								order = 40,
								args = {
									texture = {
										type = "select",
										name = "Texture",
										values = AceGUIWidgetLSMlists.background,
										get = function()
											return db[ic].types[tid].bgpanel.bg.texture
										end,
										set = function(info, value)
											db[ic].types[tid].bgpanel.bg.texture = value
											cPointDisplay:GetTextures()
											cPointDisplay:UpdateBGPanelTextures()
										end,
										dialogControl='LSM30_Background',
										order = 10,
									},
									color = {
										type = "color",
										name = "Color",
										hasAlpha = true,
										get = function(info,r,g,b,a)
											return db[ic].types[tid].bgpanel.bg.color.r, db[ic].types[tid].bgpanel.bg.color.g, db[ic].types[tid].bgpanel.bg.color.b, db[ic].types[tid].bgpanel.bg.color.a
										end,
										set = function(info,r,g,b,a)
											db[ic].types[tid].bgpanel.bg.color.r = r
											db[ic].types[tid].bgpanel.bg.color.g = g
											db[ic].types[tid].bgpanel.bg.color.b = b
											db[ic].types[tid].bgpanel.bg.color.a = a
											cPointDisplay:UpdateBGPanelTextures()
										end,
										order = 20,
									},
								},
							},
							border = {
								name = "Border",
								type = "group",
								disabled = function() if db[ic].types[tid].bgpanel.enabled then return false else return true end end,
								order = 50,
								args = {
									texture = {
										type = "select",
										name = "Texture",
										values = AceGUIWidgetLSMlists.border,
										get = function()
											return db[ic].types[tid].bgpanel.border.texture
										end,
										set = function(info, value)
											db[ic].types[tid].bgpanel.border.texture = value
											cPointDisplay:GetTextures()
											cPointDisplay:UpdateBGPanelTextures()
										end,
										dialogControl='LSM30_Border',
										order = 10,
									},
									inset = {
										type = "range",
										name = "Inset",
										min = -32, max = 32, step = 1,
										get = function(info) return db[ic].types[tid].bgpanel.border.inset end,
										set = function(info, value) 
											db[ic].types[tid].bgpanel.border.inset = value
											cPointDisplay:UpdateBGPanelTextures()
											cPointDisplay:UpdatePosition()
										end,
										order = 20,
									},
									edgesize = {
										type = "range",
										name = "Edge Size",
										min = -32, max = 32, step = 1,
										get = function(info) return db[ic].types[tid].bgpanel.border.edgesize end,
										set = function(info, value) db[ic].types[tid].bgpanel.border.edgesize = value; cPointDisplay:UpdateBGPanelTextures(); end,
										order = 30,
									},
									color = {
										type = "color",
										name = "Color",
										hasAlpha = true,
										get = function(info,r,g,b,a)
											return db[ic].types[tid].bgpanel.border.color.r, db[ic].types[tid].bgpanel.border.color.g, db[ic].types[tid].bgpanel.border.color.b, db[ic].types[tid].bgpanel.border.color.a
										end,
										set = function(info,r,g,b,a)
											db[ic].types[tid].bgpanel.border.color.r = r
											db[ic].types[tid].bgpanel.border.color.g = g
											db[ic].types[tid].bgpanel.border.color.b = b
											db[ic].types[tid].bgpanel.border.color.a = a
											cPointDisplay:UpdateBGPanelTextures()
										end,
										order = 40,
									},
								},
							},
						},
					},
					combatfader = {
						type = "group",
						name = "Combat Fader",
						childGroups = "tab",
						disabled = function() if db[ic].types[tid].enabled then return false else return true end end,
						order = 500,
						args = {
							header = {
								type = "header",
								name = "Combat Fader",
								order = 10,
							},
							desc = {
								type = "description",
								name = "Controls the fading of the Point Display based on player status.",
								order = 20,
							},
							enabled = {
								type = "toggle",
								name = "Enabled",
								desc = "Enable/Disable combat fading for this Point Display type.",
								get = function() return db[ic].types[tid].combatfader.enabled end,
								set = function(info, value) 
									db[ic].types[tid].combatfader.enabled = value
									cPointDisplay:UpdateCombatFader()
								end,
								order = 30,
							},
							sep = {
								type = "description",
								name = " ",
								order = 40,
							},
							opacity = {
								type = "group",
								name = "Opacity",
								inline = true,
								disabled = function() if db[ic].types[tid].combatfader.enabled then return false else return true end end,
								order = 60,
								args = {
									incombat = {
										type = "range",
										name = "In-combat",
										min = 0, max = 1, step = 0.05,
										isPercent = true,
										get = function(info) return db[ic].types[tid].combatfader.opacity.incombat end,
										set = function(info, value) db[ic].types[tid].combatfader.opacity.incombat = value; cPointDisplay:UpdateCombatFader(); end,
										order = 10,
									},
									hurt = {
										type = "range",
										name = "Hurt",
										min = 0, max = 1, step = 0.05,
										isPercent = true,
										get = function(info) return db[ic].types[tid].combatfader.opacity.hurt end,
										set = function(info, value) db[ic].types[tid].combatfader.opacity.hurt = value; cPointDisplay:UpdateCombatFader(); end,
										order = 20,
									},
									target = {
										type = "range",
										name = "Target-selected",
										min = 0, max = 1, step = 0.05,
										isPercent = true,
										get = function(info) return db[ic].types[tid].combatfader.opacity.target end,
										set = function(info, value) db[ic].types[tid].combatfader.opacity.target = value; cPointDisplay:UpdateCombatFader(); end,
										order = 30,
									},
									outofcombat = {
										type = "range",
										name = "Out-of-combat",
										min = 0, max = 1, step = 0.05,
										isPercent = true,
										get = function(info) return db[ic].types[tid].combatfader.opacity.outofcombat end,
										set = function(info, value) db[ic].types[tid].combatfader.opacity.outofcombat = value; cPointDisplay:UpdateCombatFader(); end,
										order = 40,
									},
								},
							},
						},
					},
				},
			}
			
			-- Bar options
			local CopyBarFromTable = {}
			for i = 1, Types[ic].points[it].barcount do
				tinsert(CopyBarFromTable, i)
				CopyBarFromTable[i] = string.format("%s %s", "Bar", i)
			end
			
			wipe(BarOpts)
			for i = 1, Types[ic].points[it].barcount do
				local BarID = string.format("%s%s", "bar", i)
				BarOpts[BarID] = {
					type = "group",
					name = string.format("%s %s", "Bar", i),
					childGroups = "tab",
					order = i,
					args = {
						copy = {
							type = "select",
							name = "Copy settings from",
							set = function(info, value)
								if value ~= i then
									cPointDisplay:CopyBarSettings(db[ic].types[tid].bars[value], db[ic].types[tid].bars[i])
									cPointDisplay:GetTextures()
									cPointDisplay:UpdateBGPanelTextures()
									cPointDisplay:UpdatePosition()
									cPointDisplay:UpdatePoints("ENABLE")
								end
							end,
							style = "dropdown",
							width = nil,
							values = CopyBarFromTable,
							order = 5,
						},
						positionsize = {
							name = "Position/Size",
							type = "group",
							order = 10,
							args = {
								size = {
									type = "group",
									name = "Size",
									inline = true,
									order = 10,
									args = {
										width = {
											type = "input",
											name = "Width",
											width = "half",
											order = 10,
											get = function(info) return tostring(db[ic].types[tid].bars[i].size.width) end,
											set = function(info, value)
												value = ValidateOffset(value)
												db[ic].types[tid].bars[i].size.width = value
												cPointDisplay:UpdatePosition()
												cPointDisplay:UpdatePoints("ENABLE")
											end,
										},
										height = {
											type = "input",
											name = "Height",
											width = "half",
											order = 20,
											get = function(info) return tostring(db[ic].types[tid].bars[i].size.height) end,
											set = function(info, value)
												value = ValidateOffset(value)
												db[ic].types[tid].bars[i].size.height = value
												cPointDisplay:UpdatePosition()
												cPointDisplay:UpdatePoints("ENABLE")
											end,
										},
									},							
								},
								position = {
									name = "Position",
									type = "group",
									inline = true,
									order = 20,
									args = {
										xoffset = {
											type = "input",
											name = "X Offset",
											desc = string.format("Push the %s display left or right. Negative values = left. Positive values = right.", TypeDesc),
											width = "half",
											order = 10,
											get = function(info) return tostring(db[ic].types[tid].bars[i].position.xofs) end,
											set = function(info, value)
												value = ValidateOffset(value)
												db[ic].types[tid].bars[i].position.xofs = value
												cPointDisplay:UpdatePosition()
											end,
										},
										yoffset = {
											type = "input",
											name = "Y Offset",
											desc = string.format("Push the %s display up or down. Negative values = down. Positive values = up.", TypeDesc),
											width = "half",
											order = 20,
											get = function(info) return tostring(db[ic].types[tid].bars[i].position.yofs) end,
											set = function(info, value)
												value = ValidateOffset(value)
												db[ic].types[tid].bars[i].position.yofs = value
												cPointDisplay:UpdatePosition()
											end,
										},
										gap = {
											type = "input",
											name = "Gap",
											desc = "Set the space between each Bar. Negative values bring them closer together. Positive values push them further apart.",
											width = "half",
											order = 30,
											get = function(info) return tostring(db[ic].types[tid].bars[i].position.gap) end,
											set = function(info, value)
												value = ValidateOffset(value)
												db[ic].types[tid].bars[i].position.gap = value
												cPointDisplay:UpdatePosition()
											end,
										},
									},
								},
							},
						},
						background = {
							name = "Background",
							type = "group",
							order = 20,
							args = {
								empty = {
									name = "Empty",
									type = "group",
									inline = true,
									order = 10,
									args = {
										texture = {
											type = "select",
											name = "Texture",
											values = AceGUIWidgetLSMlists.background,
											get = function()
												return db[ic].types[tid].bars[i].bg.empty.texture
											end,
											set = function(info, value)
												db[ic].types[tid].bars[i].bg.empty.texture = value
												cPointDisplay:GetTextures()
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											dialogControl='LSM30_Background',
											order = 10,
										},
										color = {
											type = "color",
											name = "Color",
											hasAlpha = true,
											get = function(info,r,g,b,a)
												return db[ic].types[tid].bars[i].bg.empty.color.r, db[ic].types[tid].bars[i].bg.empty.color.g, db[ic].types[tid].bars[i].bg.empty.color.b, db[ic].types[tid].bars[i].bg.empty.color.a
											end,
											set = function(info,r,g,b,a)
												db[ic].types[tid].bars[i].bg.empty.color.r = r
												db[ic].types[tid].bars[i].bg.empty.color.g = g
												db[ic].types[tid].bars[i].bg.empty.color.b = b
												db[ic].types[tid].bars[i].bg.empty.color.a = a
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											order = 20,
										},
									},
								},
								full = {
									name = "Full",
									type = "group",
									inline = true,
									order = 20,
									args = {
										texture = {
											type = "select",
											name = "Texture",
											values = AceGUIWidgetLSMlists.background,
											get = function()
												return db[ic].types[tid].bars[i].bg.full.texture
											end,
											set = function(info, value)
												db[ic].types[tid].bars[i].bg.full.texture = value
												cPointDisplay:GetTextures()
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											dialogControl='LSM30_Background',
											order = 10,
										},
										colors = {
											type = "group",
											name = "Colors",
											inline = true,
											order = 20,
											args = {
												color = {
													type = "color",
													name = "Normal",
													hasAlpha = true,
													get = function(info,r,g,b,a)
														return db[ic].types[tid].bars[i].bg.full.color.r, db[ic].types[tid].bars[i].bg.full.color.g, db[ic].types[tid].bars[i].bg.full.color.b, db[ic].types[tid].bars[i].bg.full.color.a
													end,
													set = function(info,r,g,b,a)
														db[ic].types[tid].bars[i].bg.full.color.r = r
														db[ic].types[tid].bars[i].bg.full.color.g = g
														db[ic].types[tid].bars[i].bg.full.color.b = b
														db[ic].types[tid].bars[i].bg.full.color.a = a
														cPointDisplay:UpdatePoints("ENABLE")
													end,
													order = 10,
												},
												maxcolor = {
													type = "color",
													name = "Max Points",
													desc = string.format("%s %s %s", "Set the background color of this Bar when", TypeDesc, "reaches it's maximum stacks."),
													hasAlpha = true,
													get = function(info,r,g,b,a)
														return db[ic].types[tid].bars[i].bg.full.maxcolor.r, db[ic].types[tid].bars[i].bg.full.maxcolor.g, db[ic].types[tid].bars[i].bg.full.maxcolor.b, db[ic].types[tid].bars[i].bg.full.maxcolor.a
													end,
													set = function(info,r,g,b,a)
														db[ic].types[tid].bars[i].bg.full.maxcolor.r = r
														db[ic].types[tid].bars[i].bg.full.maxcolor.g = g
														db[ic].types[tid].bars[i].bg.full.maxcolor.b = b
														db[ic].types[tid].bars[i].bg.full.maxcolor.a = a
														cPointDisplay:UpdatePoints("ENABLE")
													end,
													order = 20,
												},
											},
										},
									},
								},
							},
						},
						border = {
							name = "Border",
							type = "group",
							order = 30,
							args = {
								empty = {
									name = "Empty",
									type = "group",
									inline = true,
									order = 10,
									args = {
										texture = {
											type = "select",
											name = "Texture",
											values = AceGUIWidgetLSMlists.border,
											get = function()
												return db[ic].types[tid].bars[i].border.empty.texture
											end,
											set = function(info, value)
												db[ic].types[tid].bars[i].border.empty.texture = value
												cPointDisplay:GetTextures()
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											dialogControl='LSM30_Border',
											order = 10,
										},
										inset = {
											type = "range",
											name = "Inset",
											min = -32, max = 32, step = 1,
											get = function(info) return db[ic].types[tid].bars[i].border.empty.inset end,
											set = function(info, value) 
												db[ic].types[tid].bars[i].border.empty.inset = value
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											order = 20,
										},
										edgesize = {
											type = "range",
											name = "Edge Size",
											min = -32, max = 32, step = 1,
											get = function(info) return db[ic].types[tid].bars[i].border.empty.edgesize end,
											set = function(info, value) db[ic].types[tid].bars[i].border.empty.edgesize = value; cPointDisplay:UpdatePoints("ENABLE"); end,
											order = 30,
										},
										color = {
											type = "color",
											name = "Color",
											hasAlpha = true,
											get = function(info,r,g,b,a)
												return db[ic].types[tid].bars[i].border.empty.color.r, db[ic].types[tid].bars[i].border.empty.color.g, db[ic].types[tid].bars[i].border.empty.color.b, db[ic].types[tid].bars[i].border.empty.color.a
											end,
											set = function(info,r,g,b,a)
												db[ic].types[tid].bars[i].border.empty.color.r = r
												db[ic].types[tid].bars[i].border.empty.color.g = g
												db[ic].types[tid].bars[i].border.empty.color.b = b
												db[ic].types[tid].bars[i].border.empty.color.a = a
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											order = 40,
										},
									},
								},
								full = {
									name = "Full",
									type = "group",
									inline = true,
									order = 20,
									args = {
										texture = {
											type = "select",
											name = "Texture",
											values = AceGUIWidgetLSMlists.border,
											get = function()
												return db[ic].types[tid].bars[i].border.full.texture
											end,
											set = function(info, value)
												db[ic].types[tid].bars[i].border.full.texture = value
												cPointDisplay:GetTextures()
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											dialogControl='LSM30_Border',
											order = 10,
										},
										inset = {
											type = "range",
											name = "Inset",
											min = -32, max = 32, step = 1,
											get = function(info) return db[ic].types[tid].bars[i].border.full.inset end,
											set = function(info, value) 
												db[ic].types[tid].bars[i].border.full.inset = value
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											order = 20,
										},
										edgesize = {
											type = "range",
											name = "Edge Size",
											min = -32, max = 32, step = 1,
											get = function(info) return db[ic].types[tid].bars[i].border.full.edgesize end,
											set = function(info, value) db[ic].types[tid].bars[i].border.full.edgesize = value; cPointDisplay:UpdatePoints("ENABLE"); end,
											order = 30,
										},
										colors = {
											type = "group",
											name = "Border Color",
											inline = true,
											order = 40,
											args = {
												color = {
													type = "color",
													name = "Normal",
													hasAlpha = true,
													get = function(info,r,g,b,a)
														return db[ic].types[tid].bars[i].border.full.color.r, db[ic].types[tid].bars[i].border.full.color.g, db[ic].types[tid].bars[i].border.full.color.b, db[ic].types[tid].bars[i].border.full.color.a
													end,
													set = function(info,r,g,b,a)
														db[ic].types[tid].bars[i].border.full.color.r = r
														db[ic].types[tid].bars[i].border.full.color.g = g
														db[ic].types[tid].bars[i].border.full.color.b = b
														db[ic].types[tid].bars[i].border.full.color.a = a
														cPointDisplay:UpdatePoints("ENABLE")
													end,
													order = 10,
												},
												maxcolor = {
													type = "color",
													name = "Max Points",
													desc = string.format("%s %s %s", "Set the border color of this Bar when", TypeDesc, "reaches it's maximum stacks."),
													hasAlpha = true,
													get = function(info,r,g,b,a)
														return db[ic].types[tid].bars[i].border.full.maxcolor.r, db[ic].types[tid].bars[i].border.full.maxcolor.g, db[ic].types[tid].bars[i].border.full.maxcolor.b, db[ic].types[tid].bars[i].border.full.maxcolor.a
													end,
													set = function(info,r,g,b,a)
														db[ic].types[tid].bars[i].border.full.maxcolor.r = r
														db[ic].types[tid].bars[i].border.full.maxcolor.g = g
														db[ic].types[tid].bars[i].border.full.maxcolor.b = b
														db[ic].types[tid].bars[i].border.full.maxcolor.a = a
														cPointDisplay:UpdatePoints("ENABLE")
													end,
													order = 20,
												},
											},
										},
									},
								},
							},
						},
						spark = {
							name = "Spark",
							type = "group",
							childGroups = "tab",
							order = 40,
							args = {
								enabled = {
									type = "toggle",
									name = "Enabled",
									desc = "Enable/Disable the Spark effect.",
									get = function(info) return db[ic].types[tid].bars[i].spark.enabled end,
									set = function(info, value) db[ic].types[tid].bars[i].spark.enabled = value; cPointDisplay:UpdatePoints("ENABLE"); end,
									order = 10,
								},
								note = {
									type = "description",
									name = "Note: You will need to use your own image to get the spark effect as cPointDisplay does not include one.",
									order = 20,
								},
								position = {
									name = "Position",
									type = "group",
									order = 30,
									args = {
										xoffset = {
											type = "input",
											name = "X Offset",
											desc = "Push the Spark left or right. Negative values = left. Positive values = right.",
											width = "half",
											order = 10,
											get = function(info) return tostring(db[ic].types[tid].bars[i].spark.position.x) end,
											set = function(info, value)
												value = ValidateOffset(value)
												db[ic].types[tid].bars[i].spark.position.x = value
												cPointDisplay:UpdatePosition()
											end,
										},
										yoffset = {
											type = "input",
											name = "Y Offset",
											desc = "Push the Spark up or down. Negative values = down. Positive values = up.",
											width = "half",
											order = 20,
											get = function(info) return tostring(db[ic].types[tid].bars[i].spark.position.y) end,
											set = function(info, value)
												value = ValidateOffset(value)
												db[ic].types[tid].bars[i].spark.position.y = value
												cPointDisplay:UpdatePosition()
											end,
										},
									},
								},
								size = {
									type = "group",
									name = "Size",
									order = 40,
									args = {
										width = {
											type = "input",
											name = "Width",
											desc = "Set the width of the Spark.",
											width = "half",
											order = 10,
											get = function(info) return tostring(db[ic].types[tid].bars[i].spark.size.width) end,
											set = function(info, value)
												value = ValidateOffset(value)
												db[ic].types[tid].bars[i].spark.size.width = value
												cPointDisplay:UpdatePosition()
											end,
										},
										height = {
											type = "input",
											name = "Height",
											desc = "Set the height of the Spark.",
											width = "half",
											order = 20,
											get = function(info) return tostring(db[ic].types[tid].bars[i].spark.size.height) end,
											set = function(info, value)
												value = ValidateOffset(value)
												db[ic].types[tid].bars[i].spark.size.height = value
												cPointDisplay:UpdatePosition()
											end,
										},
									},							
								},
								bg = {
									type = "group",
									name = "Background",
									order = 50,
									args = {
										texture = {
											type = "select",
											name = "Texture",
											values = AceGUIWidgetLSMlists.background,
											get = function()
												return db[ic].types[tid].bars[i].spark.bg.texture
											end,
											set = function(info, value)
												db[ic].types[tid].bars[i].spark.bg.texture = value
												cPointDisplay:GetTextures()
												cPointDisplay:UpdatePoints("ENABLE")
											end,
											dialogControl='LSM30_Background',
											order = 10,
										},
										colors = {
											type = "group",
											name = "Colors",
											inline = true,
											order = 20,
											args = {
												color = {
													type = "color",
													name = "Normal",
													hasAlpha = true,
													get = function(info,r,g,b,a)
														return db[ic].types[tid].bars[i].spark.bg.color.r, db[ic].types[tid].bars[i].spark.bg.color.g, db[ic].types[tid].bars[i].spark.bg.color.b, db[ic].types[tid].bars[i].spark.bg.color.a
													end,
													set = function(info,r,g,b,a)
														db[ic].types[tid].bars[i].spark.bg.color.r = r
														db[ic].types[tid].bars[i].spark.bg.color.g = g
														db[ic].types[tid].bars[i].spark.bg.color.b = b
														db[ic].types[tid].bars[i].spark.bg.color.a = a
														cPointDisplay:UpdatePoints("ENABLE")
													end,
													order = 10,
												},
												maxcolor = {
													type = "color",
													name = "Full Points",
													desc = string.format("%s %s %s", "Set the border color of this Bar's spark when", TypeDesc, "reaches it's maximum stacks."),
													hasAlpha = true,
													get = function(info,r,g,b,a)
														return db[ic].types[tid].bars[i].spark.bg.maxcolor.r, db[ic].types[tid].bars[i].spark.bg.maxcolor.g, db[ic].types[tid].bars[i].spark.bg.maxcolor.b, db[ic].types[tid].bars[i].spark.bg.maxcolor.a
													end,
													set = function(info,r,g,b,a)
														db[ic].types[tid].bars[i].spark.bg.maxcolor.r = r
														db[ic].types[tid].bars[i].spark.bg.maxcolor.g = g
														db[ic].types[tid].bars[i].spark.bg.maxcolor.b = b
														db[ic].types[tid].bars[i].spark.bg.maxcolor.a = a
														cPointDisplay:UpdatePoints("ENABLE")
													end,
													order = 20,
												},
											},
										},
									},
								},								
							},
						},
					},
				};
			end
			
			-- Fill out new Types table with it's Bars
			for key, val in pairs(BarOpts) do
				TypeOpts[tid].args.bars.args[key] = (type(val) == "function") and val() or val
			end
			
			Opts_TypeOrderCnt = Opts_TypeOrderCnt + 10;
		end
		
		-- Create new Class table
		ClassOpts[ic] = {
			name = ClassID,
			type = "group",
			order = Opts_ClassOrderCnt,
			args = {},
		};
		-- Fill out new Class table with it's Types
		for key, val in pairs(TypeOpts) do
			ClassOpts[ic].args[key] = (type(val) == "function") and val() or val
		end
		
		Opts_ClassOrderCnt = Opts_ClassOrderCnt + 10;
	end
	
	-- Fill out Options table with all Classes
	for key, val in pairs(ClassOpts) do
		options.args[key] = (type(val) == "function") and val() or val
	end
end

-- Copy All Settings
function cPointDisplay:CopyAllSettings(FromTable, ToTable, FromIC, ToIC, FromTID, ToTID, FromNum, ToNum)
	if not FromTable or not ToTable then return false end
	for i,v in pairs(FromTable) do
		if type(FromTable[i]) == "table" then
			for i2,v2 in pairs(FromTable[i]) do
				if type(FromTable[i][i2]) == "table" then
					for i3,v3 in pairs(FromTable[i][i2]) do
						if type(FromTable[i][i2][i3]) == "table" then
							for i4,v4 in pairs(FromTable[i][i2][i3]) do
								if type(FromTable[i][i2][i3][i4]) == "table" then
									for i5,v5 in pairs(FromTable[i][i2][i3][i4]) do
										if type(FromTable[i][i2][i3][i4][i5]) == "table" then
											for i6,v6 in pairs(FromTable[i][i2][i3][i4][i5]) do
												if type(FromTable[i][i2][i3][i4][i5][i6]) == "table" then
													for i7,v7 in pairs(FromTable[i][i2][i3][i4][i5][i6]) do
														ToTable[i][i2][i3][i4][i5][i6][i7] = FromTable[i][i2][i3][i4][i5][i6][i7]
													end
												else
													ToTable[i][i2][i3][i4][i5][i6] = FromTable[i][i2][i3][i4][i5][i6]
												end
											end
										else
											ToTable[i][i2][i3][i4][i5] = FromTable[i][i2][i3][i4][i5]
										end
									end
								else
									ToTable[i][i2][i3][i4] = FromTable[i][i2][i3][i4]
								end
							end
						else
							ToTable[i][i2][i3] = FromTable[i][i2][i3]
						end
					end
				else
					ToTable[i][i2] = FromTable[i][i2]
				end
			end
		else
			ToTable[i] = FromTable[i]
		end
	end
	
	-- Erase any excess Point Bar info
	if Types[FromIC].points[FromNum].barcount > Types[ToIC].points[ToNum].barcount then
		local FromCount = Types[FromIC].points[FromNum].barcount + 1
		local ToCount = Types[ToIC].points[ToNum].barcount
		for i = FromCount, ToCount do
			db[ToIC].types[ToTID].bars[i] = nil
		end
	end
	
	-- Disable config mode
	db[ToIC].types[ToTID].configmode.enabled = false
	db[ToIC].types[ToTID].configmode.count = 2
	
	return true
end

-- Copy Bar Settings
function cPointDisplay:CopyBarSettings(FromTable, ToTable)
	if not FromTable or not ToTable then return false end
	for i,v in pairs(FromTable) do
		if type(FromTable[i]) == "table" then
			for i2,v2 in pairs(FromTable[i]) do
				if type(FromTable[i][i2]) == "table" then
					for i3,v3 in pairs(FromTable[i][i2]) do
						if type(FromTable[i][i2][i3]) == "table" then
							for i4,v4 in pairs(FromTable[i][i2][i3]) do
								if type(FromTable[i][i2][i3][i4]) == "table" then
									for i5,v5 in pairs(FromTable[i][i2][i3][i4]) do
										if type(FromTable[i][i2][i3][i4][i5]) == "table" then
											for i6,v6 in pairs(FromTable[i][i2][i3][i4][i5]) do
												ToTable[i][i2][i3][i4][i5][i6] = FromTable[i][i2][i3][i4][i5][i6]
											end
										else
											ToTable[i][i2][i3][i4][i5] = FromTable[i][i2][i3][i4][i5]
										end
									end
								else
									ToTable[i][i2][i3][i4] = FromTable[i][i2][i3][i4]
								end
							end
						else
							ToTable[i][i2][i3] = FromTable[i][i2][i3]
						end
					end
				else
					ToTable[i][i2] = FromTable[i][i2]
				end
			end
		else
			ToTable[i] = FromTable[i]
		end
	end
	return true
end

local intoptions = nil
local function GetIntOptions()
	if not intoptions then
		intoptions = {
			name = "cPointDisplay",
			handler = cPointDisplay,
			type = "group",
			args = {
				note = {
					type = "description",
					name = "You can access the cPointDisplay options by typing: /spd",
					order = 10,
				},
				openoptions = {
					type = "execute",
					name = "Open config...",
					func = function() 
						cPointDisplay:OpenOptions()
					end,
					order = 20,
				},
			},
		}
	end
	return intoptions
end

function cPointDisplay:OpenOptions()
	if not options then cPointDisplay:SetUpOptions() end
	LibStub("AceConfigDialog-3.0"):Open("cPointDisplay")
end

function cPointDisplay:ChatCommand(input)
	cPointDisplay:OpenOptions()
end

function cPointDisplay:ConfigRefresh()
	db = self.db.profile
end

function cPointDisplay:SetUpInitialOptions()
	-- Chat commands
	self:RegisterChatCommand("cpd", "ChatCommand")
	self:RegisterChatCommand("cPointDisplay", "ChatCommand")
	
	-- Interface panel options
	LibStub("AceConfig-3.0"):RegisterOptionsTable("cPointDisplay-Int", GetIntOptions)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("cPointDisplay-Int", "cPointDisplay")
end

function cPointDisplay:SetUpOptions()
	db = self.db.profile
	
	-- Primary options
	GetOptions()
	
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	options.args.profiles.order = 10000
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("cPointDisplay", options)
	LibStub("AceConfigDialog-3.0"):SetDefaultSize("cPointDisplay", 800, 600)
end