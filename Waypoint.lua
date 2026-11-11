local _, ns = ...
local L = ns.L

---------------------------------------------------------------------------
-- (1.27) Optional waypoint export: the spot the arrow points at is also set as a TomTom waypoint (only if TomTom is
-- installed). Off by default. (10.11.2026) the Blizzard map pin export is gone: off for everybody since 28.10.2026
-- and without a switch.
---------------------------------------------------------------------------
local INTERVAL = 1
local lastKey          -- "mapID:x:y" of the spot last exported
local tomtomUID
local ticker           -- (10.11.2026) runs only while a waypoint is exported

local function Key(t)
  return ("%d:%.4f:%.4f"):format(t.mapID, t.x, t.y)
end

local function SpotOf(target)
  if type(target) ~= "table" then return nil end
  local m, x, y = ns.Num(target.mapID), ns.Num(target.x), ns.Num(target.y)
  if not (m and x and y) or m <= 0 or x < 0 or x > 1 or y < 0 or y > 1 then return nil end
  -- (1.28) the label becomes a TomTom title: a plain, clean string or nothing
  local label = target.label
  if type(label) == "string" and ns.Usable(label) and ns.CleanName then
    label = ns.CleanName(label:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
  else
    label = nil
  end
  return { mapID = m, x = x, y = y, label = label }
end

local function ClearTomTom()
  if tomtomUID and type(TomTom) == "table" and TomTom.RemoveWaypoint then pcall(TomTom.RemoveWaypoint, TomTom, tomtomUID) end
  tomtomUID = nil
end

local function SetTomTom(spot)
  if type(TomTom) ~= "table" or not TomTom.AddWaypoint then return false end
  ClearTomTom()
  -- (1.28) only title and persistent: the other options are not documented for sure
  local ok, uid = pcall(TomTom.AddWaypoint, TomTom, spot.mapID, spot.x, spot.y, {
    title = spot.label or "Questdon", persistent = false,
  })
  if ok and uid then tomtomUID = uid end
  return ok and uid ~= nil
end

-- Looks at the arrow's target and exports it when it changed.
function ns.SyncWaypoint()
  local db = ns.db
  if not db then return end
  if not db.exportTomTom then
    if lastKey then ClearTomTom() lastKey = nil end
    -- (10.11.2026, Daniel: better without packing more in) off, the default: nothing ticks
    if ticker then if ticker.Cancel then ticker:Cancel() end ticker = nil end
    return
  end
  if not ticker and C_Timer and C_Timer.NewTicker then
    ticker = C_Timer.NewTicker(INTERVAL, function() pcall(ns.SyncWaypoint) end)
  end
  local spot = SpotOf(ns.ArrowTarget and ns.ArrowTarget())
  if not spot then
    if lastKey then ClearTomTom() lastKey = nil end
    return
  end
  local key = Key(spot)
  if key == lastKey then return end
  lastKey = key
  SetTomTom(spot)
end

function ns.WaypointState()
  return { key = lastKey, tomtom = tomtomUID ~= nil, ticking = ticker ~= nil }
end

-- the ticker starts with the switch (Options.lua onChange) or here, when it was on already
ns.OnInit(function() pcall(ns.SyncWaypoint) end)
