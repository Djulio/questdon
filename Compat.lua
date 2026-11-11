local _, ns = ...
local L = ns.L

-- Questie next to Questdon. (10.11.2026, Daniel: "Questie has priority" fixed off) Questdon no longer steps back
-- where Questie does the same; what is left is whether Questie is on and which map marks it draws (MapPins.lua,
-- pinsOnlyUnknown). Questie's settings are only read, never changed.

local function Profile()
  if not ns.AddOnLoaded("Questie") then return nil end
  local p = type(Questie) == "table" and type(Questie.db) == "table" and Questie.db.profile
  if type(p) ~= "table" or p.enabled == false then return nil end
  return p
end

-- (Questdon review 1) Questie loaded and switched on in its own options
function ns.QuestieOn() return Profile() ~= nil end
-- (Questdon review 3) Questie draws this kind of map mark itself: its map icons and the kind's own switch
-- (Questie's QuestieOptionsDefaults.lua, checked 16.10.: enableMapIcons, enableAvailable, enableObjectives,
-- enableTurnins); an option it does not have counts as on
local KIND_SWITCH = { start = "enableAvailable", objective = "enableObjectives", turnin = "enableTurnins" }
function ns.QuestieDrawsMarks(kind)
  local p = Profile()
  if not p or p.enableMapIcons == false then return false end
  -- (review 4) its minimap icons off: Questdon draws its own (world map and minimap share one pin list, so the
  -- world map may show both addons' marks then; nothing on the minimap was worse)
  if p.enableMiniMapIcons == false then return false end
  local sw = KIND_SWITCH[kind]
  return not (sw and p[sw] == false)
end

-- A Questdon feature runs when it is switched on (the two sounds share one switch).
function ns.Active(key)
  if key == "soundQuest" or key == "soundObjective" then key = "notifySound" end
  return ns.db[key]
end
