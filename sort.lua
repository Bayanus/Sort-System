-- CC:Tweaked sorter
-- Supports filtClean.json (array-based mapping)
-- Deterministic, no guessing

local fs = fs
local peripheral = peripheral
local textutils = textutils

-- =========================
-- LOAD FILTER
-- =========================

local FILTER_FILE = "filtClean.json"
local CATEGORY_CHESTS = require("category_chests")

if not fs.exists(FILTER_FILE) then
  error("filtClean.json not found")
end

local f = fs.open(FILTER_FILE, "r")
local rawFilter = textutils.unserializeJSON(f.readAll())
f.close()

if type(rawFilter) ~= "table" then
  error("Invalid filtClean.json format (expected array)")
end

-- =========================
-- BUILD LOOKUP
-- =========================

local ITEM_TO_CATEGORY = {}

for _, entry in ipairs(rawFilter) do
  if entry.id and entry.category then
    ITEM_TO_CATEGORY[entry.id] = entry.category
  end
end

print("Loaded filter entries: " .. tostring(#rawFilter))

-- =========================
-- CONFIG
-- =========================

local INPUT = "minecraft:chest_6"
local FALLBACK = "minecraft:hopper_45"

local input = peripheral.wrap(INPUT)
if not input then
  error("Input chest not found")
end

-- =========================
-- SORT LOOP
-- =========================

local function stripNamespace(id)
  return id:match(":(.+)") or id
end

while true do
  local items = input.list()
  
  for slot, item in pairs(items) do
    local category = ITEM_TO_CATEGORY[item.name]
    -- Debug ──────────────────────────────────────────────────────────────
    print("──────────────────────────────────────────────")
    print("Item: " .. item.name .. " (count: " .. item.count .. ")")
    print("  Category from JSON: " .. (category or "NIL — no in filtClean.json"))
    if category then
        local chestNum = CATEGORY_CHESTS[category]
        print("  Found in category_chests: " .. (chestNum and tostring(chestNum) or "no this key → fallback"))
        print("  Full key used for lookup: '" .. category .. "'")
    else
        print("  → Reason: items pizda rulyam")
    end
  -- ─────────────────────────────────────────────────────────────────────
    local targetChest
    local categoryName

    if category and CATEGORY_CHESTS[category] then
      targetChest = "minecraft:hopper_" .. CATEGORY_CHESTS[category]
      categoryName = category
    else
      targetChest = FALLBACK
      categoryName = "Fallback"
    end

    local moved = input.pushItems(targetChest, slot)

    if moved > 0 then
      print(
        stripNamespace(item.name)
        .. " -> "
        .. categoryName
        .. " ("
        .. moved
        .. ")"
      )
    end
  end

  sleep(0.5)
end
