AsylumTracker = AsylumTracker or {}
local AsylumTracker = AsylumTracker

local ASYLUM_SANCTORIUM = 1000
local HIGH_PRIORITY = 5
local MED_PRIORITY = 3
local LOW_PRIORITY = 1

AsylumTracker.name = "AsylumTracker"
AsylumTracker.author = "init3"
AsylumTracker.version = "1.8"
AsylumTracker.variableVersion = 1
AsylumTracker.fontSize = 48
AsylumTracker.isMovable = false
AsylumTracker.olmsHealth = 100
AsylumTracker.isInVAS = false
AsylumTracker.isInCombat = false
AsylumTracker.olmsJumping = false
AsylumTracker.firstJump = true
AsylumTracker.isRegistered = false
AsylumTracker.sphereIsUp = false
AsylumTracker.groupMembers = {}
AsylumTracker.refreshRate = 500
AsylumTracker.displayName = UndecorateDisplayName(GetUnitDisplayName("player"))
AsylumTracker.displayResolution = {
     width = GuiRoot:GetWidth(),
     height = GuiRoot:GetHeight()
}

AsylumTracker.id = {
     --Abilities for events that happen in the vAS fight
     storm_the_heavens = 98535, -- Lightning Storm
     defiling_blast = 95545, -- Llothis Poison Cone
     oppressive_bolts = 95585, -- Start of Llothis Attack that needs to be interrupted
     teleport_strike = 99138, -- Felms' Jump
     static_shield = 96010, -- Olms' Shield
     gusts_of_steam = 98868, -- Olms' jump
     trial_by_fire = 98582, -- Olms' fire below 25% HP
     scalding_roar = 98683,
     exhaustive_charges = 95482,
     maim = 95657, -- Felms' Maim
     dormant = 99990, -- Used to tell if Felms/Llothis have been taken down in HM

     -- Abilities that can be used to interrupt Llothis
     bash = 21973,
     force_shock = 48010,
     deep_breath = 32797,
     charge = 26508,
     poison_arrow = 38648,
}

AsylumTracker.defaults = {
     -- Debugging
     debug = false,
     -- Settings
     sound_enabled = true,
     llothis_notifications = true,
     felms_notifications = true,

     -- Abilities
     interrupt_message = "Toxic",
     sphere_message_toggle = false,
     sphere_message = "SPHERE",
     storm_the_heavens = true,
     defiling_blast = true,
     static_shield = true,
     teleport_strike = false,
     oppressive_bolts = false,
     trial_by_fire = false,
     scalding_roar = false,
     exhaustive_charges = false,
     maim = false,

     -- XML Offsets
     olms_hp_offsetX = AsylumTracker.displayResolution["width"] / 2,
     olms_hp_offsetY = 330,
     storm_offsetX = AsylumTracker.displayResolution["width"] / 2,
     storm_offsetY = 380,
     blast_offsetX = AsylumTracker.displayResolution["width"] / 2,
     blast_offsetY = 430,
     sphere_offsetX = AsylumTracker.displayResolution["width"] / 2,
     sphere_offsetY = 480,
     teleport_strike_offsetX = AsylumTracker.displayResolution["width"] / 2,
     teleport_strike_offsetY = 530,
     oppressive_bolts_offsetX = AsylumTracker.displayResolution["width"] / 2,
     oppressive_bolts_offsetY = 580,
     fire_offsetX = AsylumTracker.displayResolution["width"] / 2,
     fire_offsetY = 630,
     steam_offsetX = AsylumTracker.displayResolution["width"] / 2,
     steam_offsetY = 680,
     maim_offsetX = AsylumTracker.displayResolution["width"] / 2,
     maim_offsetY = 730,
     exhaustive_charges_offsetX = AsylumTracker.displayResolution["width"] / 2,
     exhaustive_charges_offsetY = 780,

     -- Font Sizes
     font_size = 48,
     font_size_olms_hp = 48,
     font_size_storm = 48,
     font_size_blast = 48,
     font_size_sphere = 48,
     font_size_teleport_strike = 48,
     font_size_oppressive_bolts = 48,
     font_size_fire = 48,
     font_size_scalding_roar = 48,
     font_size_maim = 48,
     font_size_exhaustive_charges = 48,

     -- Notification Scale
     olms_hp_scale = 1,
     storm_scale = 1,
     blast_scale = 1,
     sphere_scale = 1,
     teleport_strike_scale = 1,
     oppressive_bolts_scale = 1,
     fire_scale = 1,
     scalding_roar_scale = 1,
     maim_scale = 1,
     exhaustive_charges_scale = 1,

     -- Colors
     color_olms_hp = {1, 0.4, 0, 1},
     color_olms_hp2 = {1, 0, 0, 1},
     color_storm = {1, 1, 1, 1},
     color_storm2 = {1, 1, 0, 1},
     color_blast = {0, 1, 0, 1},
     color_sphere = {0, 0, 1, 1},
     color_sphere2 = {1, 0, 0, 1},
     color_teleport_strike = {1, 0, 1, 1},
     color_oppressive_bolts = {0, 0, 1, 1},
     color_fire = {1, 0.4, 0, 1},
     color_scalding_roar = {0.5, 0.05, 1, 1},
     color_maim = {0.2, 0.93, .79, 1},
     color_exhaustive_charges = {0.18, 0.37, 0.45, 1},

     -- Sound Effects
     storm_the_heavens_sound = "BATTLEGROUND_CAPTURE_FLAG_CAPTURED_BY_OWN_TEAM",
     storm_the_heavens_volume = 1,
     defiling_blast_sound = "BATTLEGROUND_CAPTURE_AREA_CAPTURED_OTHER_TEAM",
     defiling_blast_volume = 1,
}

AsylumTracker.timers = {
     storm_the_heavens = 0,
     defiling_blast = 0,
     teleport_strike = 0,
     oppressive_bolts = 0,
     scalding_roar = 0,
     maim = 0,
     exhaustive_charges = 0,
     felms_dormant = 0,
     llothis_dormant = 0,
}

AsylumTracker.endTimes = {}

local function dbg(text)
     if AsylumTracker.sv.debug then
          d(text)
     end
end

local function UnitIdToName(unitId)
     local name = AsylumTracker.GetNameForUnitId(unitId) -- Character name for the specified TargetUnitId
     if name == "" then
          name = "#"..unitId -- If the LibUnit function for some reason returns an empty string, it sets the name equal to #unitTargetID
     else
          if AsylumTracker.groupMembers[name] ~= nil then
               name = AsylumTracker.groupMembers[name] -- Looks up the @DisplayName for the corresponding Character
               name = UndecorateDisplayName(name)
               name = zo_strformat("<<C:1>>", name) -- Capitalizes the DisplayName
          else
               return name
          end
     end
     return name
end

--[[ Name is a bit misleading. The function is called whenever there is a change to the world map,
meaning this will not only be called when you change zones, but also whenever you're using your world map]]
local function OnZoneChanged()
     --     local zone = zo_strformat("<<C:1>>", GetUnitZone("player"))
     local zone = zo_strformat("<<C:1>>", GetUnitZone("player"))
     local targetZone = zo_strformat("<<C:1>>", GetZoneNameById(ASYLUM_SANCTORIUM))
     if zone == targetZone then -- Checks to see if the player is in Asylum Sanctorium
          AsylumTracker.isInVAS = true
          if not AsylumTracker.isRegistered then --Used to prevent re-registering events when flipping through world map
               AsylumTracker.RegisterEvents()
               AsylumTracker.isRegistered = true
          end
     else
          AsylumTracker.isInVAS = false
          if AsylumTracker.isRegistered then
               AsylumTracker.UnregisterEvents() -- Unregisters events when not in Asylum Sanctorium to save resources
               AsylumTracker.isRegistered = false
          end
     end
end

-- Sets an estimated timer for some mechanics
local function SetTimer(key)
     local duration
     if key == "storm_the_heavens" then
          duration = 40
     elseif key == "defiling_blast" then
          duration = 21
     elseif key == "teleport_strike" then
          duration = 21
     elseif key == "oppressive_bolts" then
          duration = 12
     elseif key == "exhaustive_charges" then
          duration = 12
     elseif key == "scalding_roar" then
          duration = 28
     elseif key == "llothis_dormant" then
          duration = 45
     elseif key == "felms_dormant" then
          duration = 45
     elseif key == "maim" then
          duration = 15
     end
     AsylumTracker.timers[key] = duration
     AsylumTracker.endTimes[key] = GetGameTimeSeconds() + duration
end

local function CreateNotification(text, duration, category, priority)
     local CSA = CENTER_SCREEN_ANNOUNCE
     local params = CSA:CreateMessageParams(category)
     params:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_RAID_TRIAL)
     params:SetText(text)
     params:SetLifespanMS(duration)
     params:SetPriority(priority)
     CSA:AddMessageWithParams(params)
end

function AsylumTracker.LoopSound(numberOfLoops, soundEffect)
     for i = 1, numberOfLoops do
          PlaySound(SOUNDS[soundEffect])
     end
end

function AsylumTracker.GetSounds()
     local sounds = {}
     for key, value in pairs(SOUNDS) do
          sounds[#sounds + 1] = key
          table.sort(sounds)
     end
     return sounds
end

local function SortTimers()
     local sh, sr, ec = AsylumTracker.timers["storm_the_heavens"], AsylumTracker.timers["scalding_roar"], AsylumTracker.timers["exhaustive_charges"]
     local sh_end, sr_end, ec_end = AsylumTracker.endTimes["storm_the_heavens"], AsylumTracker.endTimes["scalding_roar"], AsylumTracker.endTimes["exhaustive_charges"]
     if (sh > sr) and (sr > ec) then
          if (sr - ec < 2) and (sr - ec >= 0) and (ec > 0) then
               AsylumTracker.timers["scalding_roar"] = sr + (2 - (sr - ec))
               AsylumTracker.endTimes["scalding_roar"] = sr_end + (2 - (sr_end - ec_end))
               dbg("sh > sr > ec")
               dbg("Updated SC to: " .. AsylumTracker.timers["scalding_roar"])
          end
          if (sh - sr < 5) and (sh - sr >= 0) and (sr > 0) then
               AsylumTracker.timers["storm_the_heavens"] = sh + (6 - (sh - sr))
               AsylumTracker.endTimes["storm_the_heavens"] = sh_end + (6 - (sh_end - sr_end))
               dbg("sh > sr > ec")
               dbg("Updated SH to: " .. AsylumTracker.timers["storm_the_heavens"])
          end
     elseif (sr > sh) and (sh > ec) then
          if (sh - ec < 2) and (sh - ec >= 0) and (ec > 0) then
               AsylumTracker.timers["storm_the_heavens"] = sh + (2 - (sh - ec))
               AsylumTracker.endTimes["storm_the_heavens"] = sh_end + (2 - (sh_end - ec_end))
               dbg("sr > sh > ec")
               dbg("Updated SH to: " .. AsylumTracker.timers["storm_the_heavens"])
          end
          if (sr - sh < 6) and (sr - sh >= 0) and (sh > 0) then
               AsylumTracker.timers["scalding_roar"] = sr + (7 - (sr - sh))
               AsylumTracker.endTimes["scalding_roar"] = sr_end + (7 - (sr_end - sh_end))
               dbg("sr > sh > ec")
               dbg("Updated SC to: " .. AsylumTracker.timers["scalding_roar"])
          end
     elseif (sh > ec) and (ec > sr) then
          if (ec - sr < 5) and (ec - sr >= 0) and (sr > 0) then
               AsylumTracker.timers["exhaustive_charges"] = ec + (6 - (ec - sr))
               AsylumTracker.endTimes["exhaustive_charges"] = ec_end + (6 - (ec_end - sr_end))
               dbg("sh > ec > sr")
               dbg("Updated EC to: " .. AsylumTracker.timers["exhaustive_charges"])
          end
          if (sh - ec < 2) and (sh - ec >= 0) and (ec > 0) then
               AsylumTracker.timers["storm_the_heavens"] = sh + (2 - (sh - ec))
               AsylumTracker.endTimes["storm_the_heavens"] = sh_end + (2 - (sh_end - ec_end))
               dbg("sh > ec > sr")
               dbg("Updated SH to: " .. AsylumTracker.timers["storm_the_heavens"])
          end
     elseif (sr > ec) and (ec > sh) then
          if (ec - sh < 6) and (ec - sh >= 0) and (sh > 0) then
               AsylumTracker.timers["exhaustive_charges"] = ec + (7 - (ec - sh))
               AsylumTracker.endTimes["exhaustive_charges"] = ec_end + (7 - (ec_end - sh_end))
               dbg("sr > ec > sh")
               dbg("Updated EC to: " .. AsylumTracker.timers["exhaustive_charges"])
          end
          if (sr - ec < 2) and (sr - ec >= 0) and (ec > 0) then
               AsylumTracker.timers["scalding_roar"] = sr + (2 - (sr - ec))
               AsylumTracker.endTimes["scalding_roar"] = sr_end + (2 - (sr_end - ec_end))
               dbg("sr > ec > sh")
               dbg("Updated SC to: " .. AsylumTracker.timers["scalding_roar"])
          end
     elseif (ec > sh) and (sh > sr) then
          if (sh - sr < 5) and (sh - sr >= 0) and (sr > 0) then
               AsylumTracker.timers["storm_the_heavens"] = sh + (6 - (sh - sr))
               AsylumTracker.endTimes["storm_the_heavens"] = sh_end + (6 - (sh_end - sr_end))
               dbg("ec > sh > sr")
               dbg("Updated SH to: " .. AsylumTracker.timers["storm_the_heavens"])
          end
          if (ec - sh < 6) and (ec - sh >= 0) and (sh > 0) then
               AsylumTracker.timers["exhaustive_charges"] = ec + (7 - (ec - sh))
               AsylumTracker.endTimes["exhaustive_charges"] = ec_end + (7 - (ec_end - sh_end))
               dbg("ec > sh > sr")
               dbg("Updated EC to: " .. AsylumTracker.timers["exhaustive_charges"])
          end
     elseif (ec > sr) and (sr > sh) then
          if (sr - sh < 6) and (sr - sh >= 0) and (sh > 0) then
               AsylumTracker.timers["scalding_roar"] = sr + (7 - (sr - sh))
               AsylumTracker.endTimes["scalding_roar"] = sr_end + (7 - (sr_end - sh_end))
               dbg("ec > sr > sh")
               dbg("Updated SC to: " .. AsylumTracker.timers["scalding_roar"])
          end
          if (ec - sr < 5) and (ec - sr >= 0) and (sr > 0) then
               AsylumTracker.timers["exhaustive_charges"] = ec + (6 - (ec - sr))
               AsylumTracker.endTimes["exhaustive_charges"] = ec_end + (6 - (ec_end - sr_end))
               dbg("ec > sr > sh")
               dbg("Updated EC to: " .. AsylumTracker.timers["exhaustive_charges"])
          end
     elseif (sh > sr) and (sr == ec) then
          dbg("sh > sr == ec")
          if (sr ~= 0) then
               AsylumTracker.timers["scalding_roar"] = sr + (2 - (sr - ec))
               AsylumTracker.endTimes["scalding_roar"] = sr_end + (2 - (sr_end - ec_end))

               AsylumTracker.timers["storm_the_heavens"] = sh + (8 - (sh - AsylumTracker.timers["scalding_roar"]))
               AsylumTracker.endTimes["storm_the_heavens"] = sh_end + (8 - (sh_end - AsylumTracker.endTimes["scalding_roar"]))
          end
     elseif (sr > sh) and (sh == ec) then
          dbg("sr > sh == ec")
          if (sh ~= 0) then
               AsylumTracker.timers["storm_the_heavens"] = sh + (2 - (sh - ec))
               AsylumTracker.endTimes["storm_the_heavens"] = sh_end + (2 - (sh_end - ec_end))

               AsylumTracker.timers["scalding_roar"] = sr + (9 - (sr - AsylumTracker.timers["storm_the_heavens"]))
               AsylumTracker.endTimes["scalding_roar"] = sr_end + (9 - (sr_end - AsylumTracker.endTimes["storm_the_heavens"]))
          end
     elseif (ec > sh) and (sh == sr) then
          dbg("ec > sh == sr")
          if (sh ~= 0) then
               AsylumTracker.timers["scalding_roar"] = sr + (7 - (sr - sh))
               AsylumTracker.endTimes["scalding_roar"] = sr_end + (7 - (sr_end - sh_end))

               AsylumTracker.timers["exhaustive_charges"] = ec + (9 - (ec - AsylumTracker.timers["scalding_roar"]))
               AsylumTracker.endTimes["exhaustive_charges"] = ec_end + (9 - (ec_end - AsylumTracker.endTimes["scalding_roar"]))
          end
     elseif (sh == sr) and (sr > ec) then
          dbg("sh == sr > ec")
          if (ec ~= 0) then
               AsylumTracker.timers["storm_the_heavens"] = sh + (2 - (sh - ec))
               AsylumTracker.endTimes["storm_the_heavens"] = sh_end + (2 - (sh_end - ec_end))

               AsylumTracker.timers["scalding_roar"] = sr + (9 - (sr - AsylumTracker.timers["storm_the_heavens"]))
               AsylumTracker.endTimes["scalding_roar"] = sr_end + (9 - (sr_end - AsylumTracker.endTimes["storm_the_heavens"]))
          end
     elseif (sr == ec) and (ec > sh) then
          dbg("sr == ec > sh")
          if (sh ~= 0) then
               AsylumTracker.timers["scalding_roar"] = sr + (7 - (sr - sh))
               AsylumTracker.endTimes["scalding_roar"] = sr_end + (7 - (sr_end - sh_end))

               AsylumTracker.timers["exhaustive_charges"] = ec + (13 - (ec - AsylumTracker.timers["scalding_roar"]))
               AsylumTracker.endTimes["exhaustive_charges"] = ec_end + (13 - (ec_end - AsylumTracker.timers["scalding_roar"]))
          end
     elseif (sh == ec) and (ec > sr) then
          dbg("sh == ec > sr")
          if (sr ~= 0) then
               AsylumTracker.timers["exhaustive_charges"] = ec + (6 - (ec - sr))
               AsylumTracker.endTimes["exhaustive_charges"] = ec_end + (6 - (ec_end - sr_end))

               AsylumTracker.timers["storm_the_heavens"] = sh + (8 - (sh - AsylumTracker.timers["exhaustive_charges"]))
               AsylumTracker.endTimes["storm_the_heavens"] = sh_end + (8 - (sh_end - AsylumTracker.endTimes["exhaustive_charges"]))
          end
     else
          dbg("reee")
     end
end

local function UpdateTimers()
     if AsylumTracker.isInCombat then
          SortTimers()
          for key, value in pairs(AsylumTracker.timers) do -- The key is the ability and the value is the endTime for the event
               if AsylumTracker.timers[key] > 0 then -- If there is a timer for the specified key event
--                    AsylumTracker.timers[key] = AsylumTracker.timers[key] - (AsylumTracker.refreshRate / 1000)
                    AsylumTracker.timers[key] = (AsylumTracker.endTimes[key] - GetGameTimeSeconds())
                    if AsylumTracker.timers[key] < 0 then AsylumTracker.timers[key] = 0 end
                    local timeRemaining = AsylumTracker.timers[key]
                    dbg(key .. ": " .. timeRemaining)
                    if key == "storm_the_heavens" and timeRemaining < 6 and timeRemaining >= 0 and AsylumTracker.sv.storm_the_heavens then -- If roughly 5 seconds until the next event should happen
                         AsylumTrackerStormLabel:SetText(GetString(AST_NOTIF_KITE) .. "|cff0000" .. math.floor(timeRemaining) .. "|r") --Update the on-screen message
                         AsylumTrackerStorm:SetHidden(false) --Show the message
                         if timeRemaining > 0 and timeRemaining == math.floor(timeRemaining) then
                              if AsylumTracker.sv["sound_enabled"] then AsylumTracker.LoopSound(AsylumTracker.sv.storm_the_heavens_volume, AsylumTracker.sv.storm_the_heavens_sound) end
                         end
                    elseif key == "defiling_blast" and timeRemaining < 6 and timeRemaining >= 0 then
                         if timeRemaining >= 1 then
                              AsylumTrackerBlastLabel:SetText(GetString(AST_NOTIF_BLAST) .. "|cff0000" .. math.floor(timeRemaining) .. "|r")
                              AsylumTrackerBlast:SetHidden(false)
                         else
                              AsylumTrackerBlastLabel:SetText(GetString(AST_NOTIF_BLAST) .. "|cff0000" .. GetString(AST_SETT_SOON) .. "|r")
                              AsylumTrackerBlast:SetHidden(false)
                         end
                         if timeRemaining > 0 and timeRemaining == math.floor(timeRemaining)then
                              if AsylumTracker.sv["sound_enabled"] then AsylumTracker.LoopSound(AsylumTracker.sv.defiling_blast_volume, AsylumTracker.sv.defiling_blast_sound) end
                         end
                    elseif key == "teleport_strike" and timeRemaining < 6 and timeRemaining >= 0 then
                         AsylumTrackerTeleportStrikeLabel:SetText(GetString(AST_NOTIF_JUMP) .. "|cff0000" .. math.floor(timeRemaining) .. "|r")
                         AsylumTrackerTeleportStrike:SetHidden(false)
                    elseif key == "oppressive_bolts" and timeRemaining >= 0 then
                         if timeRemaining > 0 then
                              AsylumTrackerOppressiveBoltsLabel:SetText(GetString(AST_NOTIF_BOLTS) .. "|cff0000" .. math.floor(timeRemaining) .. "|r")
                         else
                              AsylumTrackerOppressiveBoltsLabel:SetText(GetString(AST_NOTIF_BOLTS) .. "|cff0000" .. GetString(AST_SETT_SOON) .. "|r")
                         end
                    elseif key == "exhaustive_charges" and timeRemaining < 6 and timeRemaining >= 0 and AsylumTracker.sv.exhaustive_charges then
                         AsylumTrackerChargesLabel:SetText(GetString(AST_NOTIF_CHARGES) .. "|cff0000" .. math.floor(timeRemaining) .. "|r")
                         AsylumTrackerCharges:SetHidden(false)
                    elseif key == "scalding_roar" and timeRemaining < 6 and timeRemaining >= 0 and AsylumTracker.sv.scalding_roar then
                         AsylumTrackerSteamLabel:SetText(GetString(AST_NOTIF_STEAM) .. "|cff0000" .. math.floor(timeRemaining) .. "|r")
                         AsylumTrackerSteam:SetHidden(false)
                    elseif key == "llothis_dormant" and timeRemaining >= 0 then
                         if AsylumTracker.sv["oppressive_bolts"] then
                              AsylumTrackerOppressiveBoltsLabel:SetText(GetString(AST_NOTIF_BOLTS) .. "|cff0000" .. math.floor(timeRemaining) .. "|r")
                              AsylumTrackerOppressiveBolts:SetHidden(false)
                         end
                         if timeRemaining == 10 then
                              if AsylumTracker.sv["llothis_notifications"] then
                                   CreateNotification("|cff9933" .. GetString(AST_NOTIF_LLOTHIS_IN_10) .. "|r", 3000, 5, HIGH_PRIORITY)
                              end
                         elseif timeRemaining == 5 then
                              if AsylumTracker.sv["llothis_notifications"] then
                                   CreateNotification("|cff9933" .. GetString(AST_NOTIF_LLOTHIS_IN_5) .. "|r", 3000, 5, HIGH_PRIORITY)
                              end
                         end
                    elseif key == "felms_dormant" and timeRemaining >= 0 then
                         if AsylumTracker.sv["teleport_strike"] then
                              AsylumTrackerTeleportStrikeLabel:SetText(GetString(AST_NOTIF_JUMP) .. "|cff0000" .. math.floor(timeRemaining) .. "|r")
                              AsylumTrackerTeleportStrike:SetHidden(false)
                         end
                         if timeRemaining == 10 then
                              if AsylumTracker.sv["felms_notifications"] then
                                   CreateNotification("|cff9933" .. GetString(AST_NOTIF_FELMS_IN_10) .. "|r", 3000, 5, HIGH_PRIORITY)
                              end
                         elseif timeRemaining == 5 then
                              if AsylumTracker.sv["felms_notifications"] then
                                   CreateNotification("|cff9933" .. GetString(AST_NOTIF_FELMS_IN_5) .. "|r", 3000, 5, HIGH_PRIORITY)
                              end
                         end
                    elseif key == "maim" and timeRemaining > 0 then
                         if AsylumTracker.sv["maim"] then
                              AsylumTrackerMaimLabel:SetText(GetString(AST_NOTIF_MAIM) .. "|cff0000" .. math.floor(timeRemaining) .. "|r")
                              AsylumTrackerMaim:SetHidden(false)
                         end
                    elseif key == "maim" and timeRemaining <= 0 then
                         AsylumTrackerMaim:SetHidden(true)
                    elseif key == "teleport_strike" then
                         dbg("Teleport Strike: " .. math.floor(timeRemaining))
                    elseif timeRemaining < 0 then --If the timer has run down completely, set the endTime to 0 to indicate there is not a timer running for the event
                         AsylumTracker.timers[key] = 0
                    end
               end
          end

          local bossName = zo_strformat("<<C:1>>", GetUnitName("boss1"))
          if bossName ~= "" then -- HP for Boss1 (Since the addon only loads in Asylum, this works to determining if you're in the room with Olms, because if you are not, this function returns an empty string)
               local current, max, effective = GetUnitPower("boss1", - 2)
               AsylumTracker.olmsHealth = tostring(math.floor(string.format("%.1f", current / max * 100))) -- Format's Olm's health as a percentage
               if not AsylumTracker.olmsJumping then
                    if AsylumTracker.olmsHealth >= "90" and AsylumTracker.olmsHealth <= "95" then
                         if AsylumTracker.olmsHealth >= "92" then
                              AsylumTrackerOlmsHPLabel:SetText(AsylumTracker.olmsHealth .. "%")
                              AsylumTrackerOlmsHPLabel:SetColor(unpack(AsylumTracker.sv["color_olms_hp"]))
                              AsylumTrackerOlmsHP:SetHidden(false)
                         else
                              AsylumTrackerOlmsHPLabel:SetText(AsylumTracker.olmsHealth .. "%")
                              AsylumTrackerOlmsHPLabel:SetColor(unpack(AsylumTracker.sv["color_olms_hp2"]))
                         end
                    elseif AsylumTracker.olmsHealth >= "75" and AsylumTracker.olmsHealth <= "80" then
                         if AsylumTracker.olmsHealth >= "77" then
                              AsylumTrackerOlmsHPLabel:SetText(AsylumTracker.olmsHealth .. "%")
                              AsylumTrackerOlmsHPLabel:SetColor(unpack(AsylumTracker.sv["color_olms_hp"]))
                              AsylumTrackerOlmsHP:SetHidden(false)
                         else
                              AsylumTrackerOlmsHPLabel:SetText(AsylumTracker.olmsHealth .. "%")
                              AsylumTrackerOlmsHPLabel:SetColor(unpack(AsylumTracker.sv["color_olms_hp2"]))
                         end
                    elseif AsylumTracker.olmsHealth >= "50" and AsylumTracker.olmsHealth <= "55" then
                         if AsylumTracker.olmsHealth >= "52" then
                              AsylumTrackerOlmsHPLabel:SetText(AsylumTracker.olmsHealth .. "%")
                              AsylumTrackerOlmsHPLabel:SetColor(unpack(AsylumTracker.sv["color_olms_hp"]))
                              AsylumTrackerOlmsHP:SetHidden(false)
                         else
                              AsylumTrackerOlmsHPLabel:SetText(AsylumTracker.olmsHealth .. "%")
                              AsylumTrackerOlmsHPLabel:SetColor(unpack(AsylumTracker.sv["color_olms_hp2"]))
                         end
                    elseif AsylumTracker.olmsHealth >= "25" and AsylumTracker.olmsHealth <= "30" then
                         if AsylumTracker.olmsHealth >= "27" then
                              AsylumTrackerOlmsHPLabel:SetText(AsylumTracker.olmsHealth .. "%")
                              AsylumTrackerOlmsHPLabel:SetColor(unpack(AsylumTracker.sv["color_olms_hp"]))
                              AsylumTrackerOlmsHP:SetHidden(false)
                         else
                              AsylumTrackerOlmsHPLabel:SetText(AsylumTracker.olmsHealth .. "%")
                              AsylumTrackerOlmsHPLabel:SetColor(unpack(AsylumTracker.sv["color_olms_hp2"]))
                         end
                    end
               end
          end
          -- If a Protector/Sphere is up, this will alternate the colors of warning message between red and white to make it more noticable
          if AsylumTracker.sphereIsUp then
               r, g, b, a = AsylumTrackerSphereLabel:GetColor()
               local firstColor = AsylumTracker.sv["color_sphere"]
               r = string.format("%.2f", r)
               g = string.format("%.2f", g)
               b = string.format("%.2f", b)
               firstColor[1] = string.format("%.2f", firstColor[1])
               firstColor[2] = string.format("%.2f", firstColor[2])
               firstColor[3] = string.format("%.2f", firstColor[3])
               if r == firstColor[1] and g == firstColor[2] and b == firstColor[3] then
                    AsylumTrackerSphereLabel:SetColor(unpack(AsylumTracker.sv["color_sphere2"]))
               else
                    AsylumTrackerSphereLabel:SetColor(unpack(AsylumTracker.sv["color_sphere"]))
               end
          end
          if AsylumTracker.stormIsActive then
               r, g, b, a = AsylumTrackerStormLabel:GetColor()
               local firstColor = AsylumTracker.sv["color_storm"]
               r = string.format("%.2f", r)
               g = string.format("%.2f", g)
               b = string.format("%.2f", b)
               firstColor[1] = string.format("%.2f", firstColor[1])
               firstColor[2] = string.format("%.2f", firstColor[2])
               firstColor[3] = string.format("%.2f", firstColor[3])
               if r == firstColor[1] and g == firstColor[2] and b == firstColor[3] then
                    AsylumTrackerStormLabel:SetColor(unpack(AsylumTracker.sv["color_storm2"]))
               else
                    AsylumTrackerStormLabel:SetColor(unpack(AsylumTracker.sv["color_storm"]))
               end
          end
     else -- If not in Asylum AND in combat, clear any running timers
          for key, value in pairs(AsylumTracker.timers) do
               AsylumTracker.timers[key] = 0
          end
     end
end

function AsylumTracker.IndexGroupMembers()
     local groupSize = GetGroupSize()
     if groupSize == 0 then -- If you're not in a group, but for whatever reason trying to solo Asylum, this will prevent the addon bugging out because it can't index the members in your non-existant group
          AsylumTracker.groupMembers[GetUnitName("player")] = GetUnitDisplayName("player")
     else
          for i = 1, GROUP_SIZE_MAX do -- For each member in your group
               local memberCharacterName = GetUnitName("group" .. i) -- The member's character name
               if memberCharacterName ~= nil then
                    local memberDisplayName = GetUnitDisplayName("group" .. i) -- The member's @DisplayName
                    AsylumTracker.groupMembers[memberCharacterName] = memberDisplayName -- Store them in the groupMembers table
               end
          end
     end
end

function AsylumTracker.CombatState(event, isInCombat)
     if isInCombat ~= AsylumTracker.isInCombat then
          AsylumTracker.isInCombat = isInCombat
          if isInCombat then
               AsylumTracker.IndexGroupMembers() -- Indexs the character and @DisplayNames for the members in your group when you enter combat
          else
               -- When you exit combat, this will remove any notifications that were on your screen when you left combat.
               AsylumTrackerOlmsHP:SetHidden(true)
               AsylumTrackerStorm:SetHidden(true)
               AsylumTrackerBlast:SetHidden(true)
               AsylumTrackerOppressiveBolts:SetHidden(true)
               AsylumTrackerSphere:SetHidden(true)
               AsylumTrackerTeleportStrike:SetHidden(true)
               AsylumTrackerFire:SetHidden(true)
               AsylumTrackerSteam:SetHidden(true)
               AsylumTrackerMaim:SetHidden(true)
               AsylumTrackerCharges:SetHidden(true)
          end
     end
end

function AsylumTracker.OnCombatEvent(_, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId)
     if (result == ACTION_RESULT_INTERRUPT) then
          AsylumTracker.timers["oppressive_bolts"] = 0
          AsylumTrackerOppressiveBoltsLabel:SetText(AsylumTracker.sv["interrupt_message"])
          zo_callLater(function() SetTimer("oppressive_bolts") end, 1000)
     end
     if result == ACTION_RESULT_BEGIN then
          if abilityId == AsylumTracker.id["storm_the_heavens"] then
               if not AsylumTracker.stormIsActive and AsylumTracker.sv["sound_enabled"] then
                    PlaySound(SOUNDS.BATTLEGROUND_COUNTDOWN_FINISH)
               end
               AsylumTracker.stormIsActive = true
               SetTimer("storm_the_heavens") -- Storm the Heavens just started, so create a new timer to preemtively warn for the next Storm the Heavens
               if AsylumTracker.sv.storm_the_heavens then
                    AsylumTrackerStormLabel:SetText(GetString(AST_NOTIF_KITE_NOW)) -- Sets the warning notifcation to KITE when Storm the Heavens is active
                    AsylumTrackerStorm:SetHidden(false) -- Unhides the notifcation for Storm the Heavens
               end
                    -- Storm the Heavens doesn't return a result to let you know when the storm ends, so I tell it to remove the notifcation from the screen 6 seconds after the storm started
               zo_callLater(function() AsylumTrackerStorm:SetHidden(true) AsylumTracker.stormIsActive = false end, 6000)

          elseif abilityId == AsylumTracker.id["defiling_blast"] and hitValue == 2000 then
               targetName = UnitIdToName(targetUnitId) -- Gets the @DisplayName for the player targeted by Llothis' defiling blast cone
               if targetName:sub(1, 1) == "#" then targetName = GetString(AST_SETT_YOU) end -- If UnitIdToName failed and returned #targetUnitId, then it was probably because you're not in a group, therefore it's on you
               if targetName == zo_strformat("<<C:1>>", AsylumTracker.displayName) then targetName = GetString(AST_SETT_YOU) end -- If targetName matches your @DisplayName
               if HashString(AsylumTracker.displayName) == 1325046754 then targetName = "Gary" end
               SetTimer("defiling_blast") -- Set Timer for defiling blast
               if targetName == GetString(AST_SETT_YOU) then
                    AsylumTrackerBlastLabel:SetText(GetString(AST_NOTIF_BLAST) .. "|cff0000" .. targetName .. "|r") -- States who the cone is targeting
                    if AsylumTracker.sv["sound_enabled"] then PlaySound(SOUNDS.BATTLEGROUND_COUNTDOWN_FINISH) end
               else
                    AsylumTrackerBlastLabel:SetText(GetString(AST_NOTIF_BLAST) .. targetName .. "|r") -- States who the cone is targeting
                    if AsylumTracker.sv["sound_enabled"] then PlaySound(SOUNDS.BATTLEGROUND_COUNTDOWN_FINISH) end
               end
               AsylumTrackerBlast:SetHidden(false) -- Unhides the notifcation

          elseif abilityId == AsylumTracker.id["oppressive_bolts"] then
               AsylumTracker.timers["oppressive_bolts"] = 0
               AsylumTrackerOppressiveBoltsLabel:SetText("|cff0000" .. GetString(AST_NOTIF_INTERRUPT) .. "|r")
               AsylumTrackerOppressiveBolts:SetHidden(false)

          elseif abilityId == AsylumTracker.id["teleport_strike"] then
               targetName = UnitIdToName(targetUnitId)
               if targetName:sub(1, 1) == "#" then targetName = GetString(AST_SETT_YOU) end
               if targetName == zo_strformat("<<C:1>>", AsylumTracker.displayName) then targetName = GetString(AST_SETT_YOU) end
               SetTimer("teleport_strike")
               if targetName == GetString(AST_SETT_YOU) then
                    AsylumTrackerTeleportStrikeLabel:SetText(GetString(AST_NOTIF_JUMP) .. "|cff0000" .. targetName .. "|r")
               else
                    AsylumTrackerTeleportStrikeLabel:SetText(GetString(AST_NOTIF_JUMP) .. targetName)
               end
               AsylumTrackerTeleportStrike:SetHidden(false)
               -- Removes the notifcation from the screen 2 seconds after Felm's jumps on his target
               zo_callLater(function() AsylumTrackerTeleportStrike:SetHidden(true) end, 2000)

          elseif abilityId == AsylumTracker.id["gusts_of_steam"] then
               -- Removed the HIDE notification from the screen 10 seconds after Olms starts jumping at his 90% 75% 50% 25% marks
               AsylumTrackerOlmsHPLabel:SetText(GetString(AST_NOTIF_OLMS_JUMP))
               AsylumTracker.olmsJumping = true
               if AsylumTracker.firstJump then -- First in sequence (first of his 4 jumps around the room, not referring to the 90% jump)
                    AsylumTracker.firstJump = false
                    zo_callLater(function()
                         AsylumTrackerOlmsHP:SetHidden(true)
                         AsylumTracker.olmsJumping = false
                         AsylumTracker.firstJump = true
                    end, 12000)
                    if AsylumTracker.olmsHealth > "77" then -- Olms' First Jump at 90% (Llothis Spawns)
                         if AsylumTracker.sv.defiling_blast then AsylumTracker.timers.defiling_blast = 34 end -- Around how long it takes for Llothis to cast the very first defiling blast
                         if AsylumTracker.sv.oppressive_bolts then
                              AsylumTracker.timers.oppressive_bolts = 41 -- Defiling Blast timer + 5s for the blast to finish
                              AsylumTrackerOppressiveBolts:SetHidden(false)
                         end
                    elseif AsylumTracker.olmsHealth > "52" then -- Olms' Second Jump at 75% (Felms Spawns)
                         if AsylumTracker.sv.teleport_strike then AsylumTracker.timers.teleport_strike = 34 end
                    end
               end

          elseif abilityId == AsylumTracker.id["trial_by_fire"] then
               AsylumTrackerFireLabel:SetText(GetString(AST_NOTIF_FIRE))
               AsylumTrackerFire:SetHidden(false)
               zo_callLater(function() AsylumTrackerFire:SetHidden(true) end, 8000)

          elseif abilityId == AsylumTracker.id["scalding_roar"] and hitValue == 2300 then
               SetTimer("scalding_roar")
               if AsylumTracker.sv.scalding_roar then
                    dbg(GetAbilityName(abilityId) .. " (" .. abilityId .. ") with a result of " .. result .. " and a hit value of " .. hitValue)
                    AsylumTrackerSteamLabel:SetText(GetString(AST_NOTIF_STEAM) .. "|cff0000" .. GetString(AST_SETT_NOW) .. "|r")
                    AsylumTrackerSteam:SetHidden(false)
                    zo_callLater(function() AsylumTrackerSteam:SetHidden(true) end, 5000)
               end

          elseif abilityId == AsylumTracker.id["exhaustive_charges"] then
               SetTimer("exhaustive_charges")
               AsylumTrackerChargesLabel:SetText(GetString(AST_NOTIF_CHARGES) .. "|cff0000" .. GetString(AST_SETT_NOW) .. "|r")
               AsylumTrackerCharges:SetHidden(false)
               zo_callLater(function() AsylumTrackerCharges:SetHidden(true) end, 2000)
          end
     end
     if result == ACTION_RESULT_EFFECT_GAINED then
          if abilityId == AsylumTracker.id["static_shield"] then -- Instead of tracking when the protector spawns, I track when the protector gives Olms a shield
               AsylumTracker.sphereIsUp = true -- If Olms has a shield, then a protector is active
               AsylumTrackerSphereLabel:SetText(GetString(AST_NOTIF_PROTECTOR))
               AsylumTrackerSphere:SetHidden(false)
          elseif abilityId == AsylumTracker.id["maim"] then
               targetName = UnitIdToName(targetUnitId)
               if targetName:sub(1, 1) == "#" then targetName = zo_strformat("<<C:1>>", AsylumTracker.displayName) end
               if targetName == zo_strformat("<<C:1>>", AsylumTracker.displayName) or targetName == GetUnitName("player") then
                    SetTimer("maim")
               end
          end
     end
     if result == ACTION_RESULT_EFFECT_FADED then
          if abilityId == AsylumTracker.id["defiling_blast"] then
               AsylumTrackerBlast:SetHidden(true) -- Hides defiling blast notification when the cone ends
          elseif abilityId == AsylumTracker.id["static_shield"] then -- All spheres dead, shield goes down.
               AsylumTracker.sphereIsUp = false
               AsylumTrackerSphere:SetHidden(true)
          elseif abilityId == AsylumTracker.id["oppressive_bolts"] then
               SetTimer("oppressive_bolts")
          end
     end
     if result == ACTION_RESULT_DIED then
          targetName = UnitIdToName(targetUnitId)
          if targetName:sub(1, 1) == "#" then targetName = zo_strformat("<<C:1>>", AsylumTracker.displayName) end
          if targetName == zo_strformat("<<C:1>>", AsylumTracker.displayName) or targetName == GetUnitName("player") then
               AsylumTracker.timers["maim"] = 0
               AsylumTrackerMaim:SetHidden(true)
          end
     end
end

function AsylumTracker.OnEffectChanged(_, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceType)
     if abilityId == AsylumTracker.id["dormant"] then
          if changeType == EFFECT_RESULT_GAINED then
               if unitName:find("Llothis") or unitName:find("ロシス") or unitName:find("ллотис") then
                    AsylumTracker.timers["defiling_blast"] = 0 -- Stops the Defiling Blast timer if Llothis gets taken down
                    AsylumTracker.timers["oppressive_bolts"] = 0
                    AsylumTrackerBlast:SetHidden(true)
                    if AsylumTracker.sv["llothis_notifications"] then
                         CreateNotification("|c00ff00" .. GetString(AST_NOTIF_LLOTHIS_DOWN) .. "|r", 3000, 5, MED_PRIORITY)
                    end
                    SetTimer("llothis_dormant")
               elseif unitName:find("Felms") or unitName:find("フェルムス") or unitName:find("фелмс") then
                    AsylumTracker.timers["teleport_strike"] = 0 -- Stops the Teleport Strike timer if Felms gets taken down
                    AsylumTrackerTeleportStrike:SetHidden(true)
                    if AsylumTracker.sv["felms_notifications"] then
                         CreateNotification("|c00ff00" .. GetString(AST_NOTIF_FELMS_DOWN) .. "|r", 3000, 5, MED_PRIORITY)
                    end
                    SetTimer("felms_dormant")
               end
          elseif changeType == EFFECT_RESULT_FADED then
               if unitName:find("Llothis") or unitName:find("ロシス") or unitName:find("ллотис") then
                    AsylumTracker.timers["llothis_dormant"] = 0
                    if AsylumTracker.sv["llothis_notifications"] then
                         CreateNotification("|c00ff00" .. GetString(AST_NOTIF_LLOTHIS_UP) .. "|r", 3000, 5, MED_PRIORITY)
                    end
               elseif unitName:find("Felms") or unitName:find("フェルムス") or unitName:find("фелмс") then
                    AsylumTracker.timers["felms_dormant"] = 0
                    if AsylumTracker.sv["felms_notifications"] then
                         CreateNotification("|c00ff00" .. GetString(AST_NOTIF_FELMS_UP) .. "|r", 3000, 5, MED_PRIORITY)
                    end
               end
          end
     end
end

function AsylumTracker.RegisterEvents()
     if AsylumTracker.isInVAS then -- Only register events if player is in Asylum to save resources
          local abilities = {} -- Stores event ids to be registered
          local eventName = AsylumTracker.name .. "_event_" -- Each filter must be registered separately, and must therefore have a different unique identifier.
          local eventIndex = 0
          local function RegisterForAbility(abilityId)
               if not abilities[abilityId] then -- If ability has not yet been registered
                    abilities[abilityId] = true
                    eventIndex = eventIndex + 1
                    EVENT_MANAGER:RegisterForEvent(eventName .. eventIndex, EVENT_COMBAT_EVENT, AsylumTracker.OnCombatEvent) -- Registers all combat events
                    EVENT_MANAGER:AddFilterForEvent(eventName .. eventIndex, EVENT_COMBAT_EVENT, REGISTER_FILTER_ABILITY_ID, abilityId) -- Filters the event to a specific ability
               end
          end

          -- Only registers abilities enabled in the settings
          for x, y in pairs(AsylumTracker.id) do
               if AsylumTracker.sv[x] and type(y) == "number" then
                    RegisterForAbility(y)
               end
          end
          if AsylumTracker.sv["oppressive_bolts"] then
               -- These are needed for tracking interrupts on Llothis
               RegisterForAbility(AsylumTracker.id["bash"])
               RegisterForAbility(AsylumTracker.id["force_shock"])
               RegisterForAbility(AsylumTracker.id["deep_breath"])
               RegisterForAbility(AsylumTracker.id["charge"])
               RegisterForAbility(AsylumTracker.id["poison_arrow"])
          end
          RegisterForAbility(AsylumTracker.id["gusts_of_steam"]) -- Olms Jump at 90/75/50/25
          -- Registers Olms' Steam Breath regardless of whether it is to be displayed in order to correctly track Olms' Storm the Heavens Timer
          if not AsylumTracker.sv.scalding_roar then RegisterForAbility(AsylumTracker.id["scalding_roar"]) end
          if not AsylumTracker.sv.storm_the_heavens then RegisterForAbility(AsylumTracker.id["storm_the_heavens"]) end
          if not AsylumTracker.sv.exhaustive_charges then RegisterForAbility(AsylumTracker.id["exhaustive_charges"]) end

          EVENT_MANAGER:RegisterForEvent(AsylumTracker.name, EVENT_PLAYER_COMBAT_STATE, AsylumTracker.CombatState) -- Used to determine player's combat state
          EVENT_MANAGER:RegisterForEvent(AsylumTracker.name .. "_dormant", EVENT_EFFECT_CHANGED, AsylumTracker.OnEffectChanged) -- Used to determine if Llothis/Felms go down
          EVENT_MANAGER:AddFilterForEvent(AsylumTracker.name .. "_dormant", EVENT_EFFECT_CHANGED, REGISTER_FILTER_ABILITY_ID, AsylumTracker.id["dormant"]) -- Filters the previous event to the dormant id
          EVENT_MANAGER:RegisterForEvent(AsylumTracker.name .. "_dead", EVENT_COMBAT_EVENT, AsylumTracker.OnCombatEvent)
          EVENT_MANAGER:AddFilterForEvent(AsylumTracker.name .. "_dead", EVENT_COMBAT_EVENT, REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_DIED)
          EVENT_MANAGER:RegisterForUpdate(AsylumTracker.name, AsylumTracker.refreshRate, UpdateTimers) -- Calls this function every half second to update timers and Olm's health
     end
end

-- Unregisters events if not in Asylum Sanctorium
function AsylumTracker.UnregisterEvents()
     if not AsylumTracker.isInVAS then
          local eventName = AsylumTracker.name .. "_event_"
          eventIndex = 0
          for x, y in pairs(AsylumTracker.id) do
               eventIndex = eventIndex + 1
               EVENT_MANAGER:UnregisterForEvent(eventName .. eventIndex, EVENT_COMBAT_EVENT)
          end

          EVENT_MANAGER:UnregisterForEvent(AsylumTracker.name, EVENT_PLAYER_COMBAT_STATE, AsylumTracker.CombatState)
          EVENT_MANAGER:UnregisterForEvent(AsylumTracker.name, EVENT_EFFECT_CHANGED, AsylumTracker.OnEffectChanged)
          EVENT_MANAGER:UnregisterForUpdate(AsylumTracker.name)
     end
end

local function RGBToHex(r, g, b, a)
     r = string.format("%x", r * 255)
     g = string.format("%x", g * 255)
     b = string.format("%x", b * 255)
     if #r < 2 then r = "0" .. r end
     if #g < 2 then g = "0" .. g end
     if #b < 2 then b = "0" .. b end
     return r .. g .. b
end

function AsylumTracker.ToggleMovable()
     AsylumTracker.isMovable = not AsylumTracker.isMovable
     if AsylumTracker.isMovable then
          local hex_olms_hp = RGBToHex(unpack(AsylumTracker.sv["color_olms_hp"]))
          local hex_olms_hp2 = RGBToHex(unpack(AsylumTracker.sv["color_olms_hp2"]))
          AsylumTrackerOlmsHPLabel:SetText("|c" .. hex_olms_hp .. GetString(AST_PREVIEW_OLMS_HP_1) .. "|r|c" .. hex_olms_hp2 .. GetString(AST_PREVIEW_OLMS_HP_2) .. "|r")
          local hex_storm = RGBToHex(unpack(AsylumTracker.sv["color_storm"]))
          local hex_storm2 = RGBToHex(unpack(AsylumTracker.sv["color_storm2"]))
          AsylumTrackerStormLabel:SetText("|c" .. hex_storm .. GetString(AST_PREVIEW_STORM_1) .. "|r|c" .. hex_storm2 .. GetString(AST_PREVIEW_STORM_2) .. "|r")
          AsylumTrackerBlastLabel:SetText(GetString(AST_PREVIEW_BLAST))
          local hex_sphere = RGBToHex(unpack(AsylumTracker.sv["color_sphere"]))
          local hex_sphere2 = RGBToHex(unpack(AsylumTracker.sv["color_sphere2"]))
          AsylumTrackerSphereLabel:SetText("|c" .. hex_sphere .. GetString(AST_PREVIEW_SPHERE_1) .. "|r|c" .. hex_sphere2 .. GetString(AST_PREVIEW_SPHERE_2) .. "|r")
          AsylumTrackerTeleportStrikeLabel:SetText(GetString(AST_PREVIEW_JUMP))
          AsylumTrackerOppressiveBoltsLabel:SetText(GetString(AST_PREVIEW_BOLTS))
          AsylumTrackerFireLabel:SetText(GetString(AST_PREVIEW_FIRE))
          AsylumTrackerSteamLabel:SetText(GetString(AST_PREVIEW_STEAM))
          AsylumTrackerMaimLabel:SetText(GetString(AST_PREVIEW_MAIM))
          AsylumTrackerChargesLabel:SetText(GetString(AST_PREVIEW_CHARGES))

          AsylumTrackerOlmsHP:SetMovable(true)
          if AsylumTracker.sv["storm_the_heavens"] then AsylumTrackerStorm:SetMovable(true) end
          if AsylumTracker.sv["defiling_blast"] then AsylumTrackerBlast:SetMovable(true) end
          if AsylumTracker.sv["static_shield"] then AsylumTrackerSphere:SetMovable(true) end
          if AsylumTracker.sv["teleport_strike"] then AsylumTrackerTeleportStrike:SetMovable(true) end
          if AsylumTracker.sv["oppressive_bolts"] then AsylumTrackerOppressiveBolts:SetMovable(true) end
          if AsylumTracker.sv["trial_by_fire"] then AsylumTrackerFire:SetMovable(true) end
          if AsylumTracker.sv["scalding_roar"] then AsylumTrackerSteam:SetMovable(true) end
          if AsylumTracker.sv["maim"] then AsylumTrackerMaim:SetMovable(true) end
          if AsylumTracker.sv["exhaustive_charges"] then AsylumTrackerCharges:SetMovable(true) end

          AsylumTrackerOlmsHP:SetHidden(false)
          if AsylumTracker.sv["storm_the_heavens"] then AsylumTrackerStorm:SetHidden(false) end
          if AsylumTracker.sv["defiling_blast"] then AsylumTrackerBlast:SetHidden(false) end
          if AsylumTracker.sv["static_shield"] then AsylumTrackerSphere:SetHidden(false) end
          if AsylumTracker.sv["teleport_strike"] then AsylumTrackerTeleportStrike:SetHidden(false) end
          if AsylumTracker.sv["oppressive_bolts"] then AsylumTrackerOppressiveBolts:SetHidden(false) end
          if AsylumTracker.sv["trial_by_fire"] then AsylumTrackerFire:SetHidden(false) end
          if AsylumTracker.sv["scalding_roar"] then AsylumTrackerSteam:SetHidden(false) end
          if AsylumTracker.sv["maim"] then AsylumTrackerMaim:SetHidden(false) end
          if AsylumTracker.sv["exhaustive_charges"] then AsylumTrackerCharges:SetHidden(false) end
     else
          AsylumTrackerOlmsHP:SetMovable(false)
          AsylumTrackerStorm:SetMovable(false)
          AsylumTrackerBlast:SetMovable(false)
          AsylumTrackerSphere:SetMovable(false)
          AsylumTrackerTeleportStrike:SetMovable(false)
          AsylumTrackerOppressiveBolts:SetMovable(false)
          AsylumTrackerFire:SetMovable(false)
          AsylumTrackerSteam:SetMovable(false)
          AsylumTrackerMaim:SetMovable(false)
          AsylumTrackerCharges:SetMovable(false)

          AsylumTrackerOlmsHP:SetHidden(true)
          AsylumTrackerStorm:SetHidden(true)
          AsylumTrackerBlast:SetHidden(true)
          AsylumTrackerSphere:SetHidden(true)
          AsylumTrackerTeleportStrike:SetHidden(true)
          AsylumTrackerOppressiveBolts:SetHidden(true)
          AsylumTrackerFire:SetHidden(true)
          AsylumTrackerSteam:SetHidden(true)
          AsylumTrackerMaim:SetHidden(true)
          AsylumTrackerCharges:SetHidden(true)
     end
end

function AsylumTracker.SetFontSize(label, size)
     local label = label
     local size = size
     local path = "EsoUI/Common/Fonts/univers67.otf"
     local outline = "soft-shadow-thick"
     label:SetFont(path .. "|" .. size .. "|" .. outline)
end

function AsylumTracker.SetScale(label, scale)
     local label = label
     local size = size
     label:SetScale(scale)
end

function AsylumTracker.ResetAnchors()
     AsylumTrackerOlmsHP:ClearAnchors()
     AsylumTrackerStorm:ClearAnchors()
     AsylumTrackerBlast:ClearAnchors()
     AsylumTrackerSphere:ClearAnchors()
     AsylumTrackerTeleportStrike:ClearAnchors()
     AsylumTrackerOppressiveBolts:ClearAnchors()
     AsylumTrackerFire:ClearAnchors()
     AsylumTrackerSteam:ClearAnchors()
     AsylumTrackerMaim:ClearAnchors()
     AsylumTrackerCharges:ClearAnchors()

     AsylumTrackerOlmsHP:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["olms_hp_offsetX"], AsylumTracker.sv["olms_hp_offsetY"])
     AsylumTrackerStorm:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["storm_offsetX"], AsylumTracker.sv["storm_offsetY"])
     AsylumTrackerBlast:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["blast_offsetX"], AsylumTracker.sv["blast_offsetY"])
     AsylumTrackerSphere:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["sphere_offsetX"], AsylumTracker.sv["sphere_offsetY"])
     AsylumTrackerTeleportStrike:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["teleport_strike_offsetX"], AsylumTracker.sv["teleport_strike_offsetY"])
     AsylumTrackerOppressiveBolts:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["oppressive_bolts_offsetX"], AsylumTracker.sv["oppressive_bolts_offsetY"])
     AsylumTrackerFire:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["fire_offsetX"], AsylumTracker.sv["fire_offsetY"])
     AsylumTrackerSteam:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["steam_offsetX"], AsylumTracker.sv["steam_offsetY"])
     AsylumTrackerMaim:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["maim_offsetX"], AsylumTracker.sv["maim_offsetY"])
     AsylumTrackerCharges:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["exhaustive_charges_offsetX"], AsylumTracker.sv["exhaustive_charges_offsetY"])
end

function AsylumTracker.SavePosition()
     AsylumTracker.sv["olms_hp_offsetX"] = AsylumTrackerOlmsHP:GetLeft()
     AsylumTracker.sv["olms_hp_offsetY"] = AsylumTrackerOlmsHP:GetTop()
     AsylumTracker.sv["storm_offsetX"] = AsylumTrackerStorm:GetLeft()
     AsylumTracker.sv["storm_offsetY"] = AsylumTrackerStorm:GetTop()
     AsylumTracker.sv["blast_offsetX"] = AsylumTrackerBlast:GetLeft()
     AsylumTracker.sv["blast_offsetY"] = AsylumTrackerBlast:GetTop()
     AsylumTracker.sv["sphere_offsetX"] = AsylumTrackerSphere:GetLeft()
     AsylumTracker.sv["sphere_offsetY"] = AsylumTrackerSphere:GetTop()
     AsylumTracker.sv["teleport_strike_offsetX"] = AsylumTrackerTeleportStrike:GetLeft()
     AsylumTracker.sv["teleport_strike_offsetY"] = AsylumTrackerTeleportStrike:GetTop()
     AsylumTracker.sv["oppressive_bolts_offsetX"] = AsylumTrackerOppressiveBolts:GetLeft()
     AsylumTracker.sv["oppressive_bolts_offsetY"] = AsylumTrackerOppressiveBolts:GetTop()
     AsylumTracker.sv["fire_offsetX"] = AsylumTrackerFire:GetLeft()
     AsylumTracker.sv["fire_offsetY"] = AsylumTrackerFire:GetTop()
     AsylumTracker.sv["steam_offsetX"] = AsylumTrackerSteam:GetLeft()
     AsylumTracker.sv["steam_offsetY"] = AsylumTrackerSteam:GetTop()
     AsylumTracker.sv["maim_offsetX"] = AsylumTrackerMaim:GetLeft()
     AsylumTracker.sv["maim_offsetY"] = AsylumTrackerMaim:GetTop()
     AsylumTracker.sv["exhaustive_charges_offsetX"] = AsylumTrackerCharges:GetLeft()
     AsylumTracker.sv["exhaustive_charges_offsetY"] = AsylumTrackerCharges:GetTop()
end

function AsylumTracker.ResetToDefaults()
     AsylumTracker.sv["olms_hp_offsetX"] = AsylumTracker.defaults["olms_hp_offsetX"]
     AsylumTracker.sv["olms_hp_offsetY"] = AsylumTracker.defaults["olms_hp_offsetY"]
     AsylumTracker.sv["storm_offsetX"] = AsylumTracker.defaults["storm_offsetX"]
     AsylumTracker.sv["storm_offsetY"] = AsylumTracker.defaults["storm_offsetY"]
     AsylumTracker.sv["blast_offsetX"] = AsylumTracker.defaults["blast_offsetX"]
     AsylumTracker.sv["blast_offsetY"] = AsylumTracker.defaults["blast_offsetY"]
     AsylumTracker.sv["sphere_offsetX"] = AsylumTracker.defaults["sphere_offsetX"]
     AsylumTracker.sv["sphere_offsetY"] = AsylumTracker.defaults["sphere_offsetY"]
     AsylumTracker.sv["teleport_strike_offsetX"] = AsylumTracker.defaults["teleport_strike_offsetX"]
     AsylumTracker.sv["teleport_strike_offsetY"] = AsylumTracker.defaults["teleport_strike_offsetY"]
     AsylumTracker.sv["oppressive_bolts_offsetX"] = AsylumTracker.defaults["oppressive_bolts_offsetX"]
     AsylumTracker.sv["oppressive_bolts_offsetY"] = AsylumTracker.defaults["oppressive_bolts_offsetY"]
     AsylumTracker.sv["fire_offsetX"] = AsylumTracker.defaults["fire_offsetX"]
     AsylumTracker.sv["fire_offsetY"] = AsylumTracker.defaults["fire_offsetY"]
     AsylumTracker.sv["steam_offsetX"] = AsylumTracker.defaults["steam_offsetX"]
     AsylumTracker.sv["steam_offsetY"] = AsylumTracker.defaults["steam_offsetY"]
     AsylumTracker.sv["maim_offsetX"] = AsylumTracker.defaults["maim_offsetX"]
     AsylumTracker.sv["maim_offsetY"] = AsylumTracker.defaults["maim_offsetY"]
     AsylumTracker.sv["exhaustive_charges_offsetX"] = AsylumTracker.defaults["exhaustive_charges_offsetX"]
     AsylumTracker.sv["exhaustive_charges_offsetY"] = AsylumTracker.defaults["exhaustive_charges_offsetY"]

     AsylumTrackerOlmsHP:ClearAnchors()
     AsylumTrackerStorm:ClearAnchors()
     AsylumTrackerBlast:ClearAnchors()
     AsylumTrackerSphere:ClearAnchors()
     AsylumTrackerTeleportStrike:ClearAnchors()
     AsylumTrackerOppressiveBolts:ClearAnchors()
     AsylumTrackerFire:ClearAnchors()
     AsylumTrackerSteam:ClearAnchors()
     AsylumTrackerMaim:ClearAnchors()
     AsylumTrackerCharges:ClearAnchors()

     AsylumTrackerOlmsHP:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["olms_hp_offsetX"], AsylumTracker.sv["olms_hp_offsetY"])
     AsylumTrackerStorm:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["storm_offsetX"], AsylumTracker.sv["storm_offsetY"])
     AsylumTrackerBlast:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["blast_offsetX"], AsylumTracker.sv["blast_offsetY"])
     AsylumTrackerSphere:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["sphere_offsetX"], AsylumTracker.sv["sphere_offsetY"])
     AsylumTrackerTeleportStrike:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["teleport_strike_offsetX"], AsylumTracker.sv["teleport_strike_offsetY"])
     AsylumTrackerOppressiveBolts:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["oppressive_bolts_offsetX"], AsylumTracker.sv["oppressive_bolts_offsetY"])
     AsylumTrackerFire:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["fire_offsetX"], AsylumTracker.sv["fire_offsetY"])
     AsylumTrackerSteam:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["steam_offsetX"], AsylumTracker.sv["steam_offsetY"])
     AsylumTrackerMaim:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["maim_offsetX"], AsylumTracker.sv["maim_offsetY"])
     AsylumTrackerCharges:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, AsylumTracker.sv["exhaustive_charges_offsetX"], AsylumTracker.sv["exhaustive_charges_offsetY"])
end

-- Initialization function
function AsylumTracker.Initialize()
     AsylumTracker.savedVars = ZO_SavedVars:NewCharacterIdSettings("AsylumTrackerVars", AsylumTracker.variableVersion, nil, AsylumTracker.defaults) -- Defines saved variables
     AsylumTracker.sv = AsylumTrackerVars["Default"][GetDisplayName()][GetCurrentCharacterId()]
     AsylumTracker.CreateSettingsWindow() -- Creates the addon settings menu
     AsylumTracker.RegisterUnitIndexing()
     AsylumTracker.ResetAnchors()

     AsylumTracker.SetFontSize(AsylumTrackerOlmsHPLabel, AsylumTracker.sv["font_size_olms_hp"])
     AsylumTracker.SetFontSize(AsylumTrackerStormLabel, AsylumTracker.sv["font_size_storm"])
     AsylumTracker.SetFontSize(AsylumTrackerBlastLabel, AsylumTracker.sv["font_size_blast"])
     AsylumTracker.SetFontSize(AsylumTrackerSphereLabel, AsylumTracker.sv["font_size_sphere"])
     AsylumTracker.SetFontSize(AsylumTrackerTeleportStrikeLabel, AsylumTracker.sv["font_size_teleport_strike"])
     AsylumTracker.SetFontSize(AsylumTrackerOppressiveBoltsLabel, AsylumTracker.sv["font_size_oppressive_bolts"])
     AsylumTracker.SetFontSize(AsylumTrackerFireLabel, AsylumTracker.sv["font_size_fire"])
     AsylumTracker.SetFontSize(AsylumTrackerSteamLabel, AsylumTracker.sv["font_size_scalding_roar"])
     AsylumTracker.SetFontSize(AsylumTrackerMaimLabel, AsylumTracker.sv["font_size_maim"])
     AsylumTracker.SetFontSize(AsylumTrackerChargesLabel, AsylumTracker.sv["font_size_exhaustive_charges"])

     AsylumTracker.SetScale(AsylumTrackerOlmsHPLabel, AsylumTracker.sv["olms_hp_scale"])
     AsylumTracker.SetScale(AsylumTrackerStormLabel, AsylumTracker.sv["storm_scale"])
     AsylumTracker.SetScale(AsylumTrackerBlastLabel, AsylumTracker.sv["blast_scale"])
     AsylumTracker.SetScale(AsylumTrackerSphereLabel, AsylumTracker.sv["sphere_scale"])
     AsylumTracker.SetScale(AsylumTrackerTeleportStrikeLabel, AsylumTracker.sv["teleport_strike_scale"])
     AsylumTracker.SetScale(AsylumTrackerOppressiveBoltsLabel, AsylumTracker.sv["oppressive_bolts_scale"])
     AsylumTracker.SetScale(AsylumTrackerFireLabel, AsylumTracker.sv["fire_scale"])
     AsylumTracker.SetScale(AsylumTrackerSteamLabel, AsylumTracker.sv["scalding_roar_scale"])
     AsylumTracker.SetScale(AsylumTrackerMaimLabel, AsylumTracker.sv["maim_scale"])
     AsylumTracker.SetScale(AsylumTrackerChargesLabel, AsylumTracker.sv["exhaustive_charges_scale"])

     if AsylumTracker.sv.sphere_message_toggle then
          ZO_CreateStringId("AST_NOTIF_PROTECTOR", AsylumTracker.sv.sphere_message)
     end

     AsylumTracker.IndexGroupMembers()

     SLASH_COMMANDS["/astrackertoggle"] = function() AsylumTracker.ToggleMovable() end
     SLASH_COMMANDS["/astrackerreset"] = function() AsylumTracker.ResetToDefaults() end
end

function AsylumTracker.OnAddOnLoaded(event, addonName)
     if AsylumTracker.name ~= addonName then return end
     CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", OnZoneChanged) -- Registers the callback used to determine which zone the player is in.
     AsylumTracker.Initialize()
     EVENT_MANAGER:UnregisterForEvent(AsylumTracker.name, EVENT_ADD_ON_LOADED) -- Unregisters the OnAddOnLoaded Function
end

EVENT_MANAGER:RegisterForEvent(AsylumTracker.name, EVENT_ADD_ON_LOADED, AsylumTracker.OnAddOnLoaded)
