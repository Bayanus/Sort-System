-- ────────────────────────────────────────────────
-- CONFIG
-- ────────────────────────────────────────────────

local INPUT_CHEST_NAME  = "minecraft:chest_2"   -- input chest
local FALLBACK_CHEST    = "minecraft:hopper_45"  -- fallback

local FILTER_FILE = "filtClean.json"

-- ────────────────────────────────────────────────
-- Globals for stats
-- ────────────────────────────────────────────────

local stats = {
    totalProcessed = 0,
    fallbackCount  = 0,
    byCategory     = {},     -- category → count
}

-- ────────────────────────────────────────────────
-- Find monitor automatically
-- ────────────────────────────────────────────────

local monitor = peripheral.find("monitor")
if not monitor then
    printError("No monitor found nearby!")
    return
end

-- Setup monitor
monitor.setTextScale(0.5)   -- smaller text = more fits (0.5–2.0)
local w, h = monitor.getSize()
monitor.setBackgroundColor(colors.black)
monitor.clear()

-- ────────────────────────────────────────────────
-- Load filter
-- ────────────────────────────────────────────────

local ITEM_TO_CATEGORY = {}
local filterFile = fs.open(FILTER_FILE, "r")
if filterFile then
    local content = filterFile.readAll()
    filterFile.close()

    local data = textutils.unserializeJSON(content)
    if data and type(data) == "table" then
        for _, entry in ipairs(data) do
            local id = entry.id
            -- Safety: add minecraft: if missing (vanilla items)
            if not id:find(":", 1, true) then
                id = "minecraft:" .. id
            end
            ITEM_TO_CATEGORY[id] = entry.category
        end
        print("Loaded " .. #data .. " filter entries")
    else
        printError("Failed to parse " .. FILTER_FILE)
    end
else
    printError("Cannot open " .. FILTER_FILE)
end

-- ────────────────────────────────────────────────
-- Category → chest mapping (from your category_chests.lua)
-- ────────────────────────────────────────────────

local CATEGORY_CHESTS = dofile("category_chests.lua") or {}
local FALLBACK = FALLBACK_CHEST

-- ────────────────────────────────────────────────
-- Helpers
-- ────────────────────────────────────────────────

local function wrapPeripheral(name)
    local p = peripheral.wrap(name)
    if not p then
        print("Warning: chest " .. name .. " not found!")
    end
    return p
end

local input = wrapPeripheral(INPUT_CHEST_NAME)
local fallbackChest = wrapPeripheral(FALLBACK)

-- ────────────────────────────────────────────────
-- Draw beautiful monitor UI
-- ────────────────────────────────────────────────

local function drawUI()
    monitor.clear()
    monitor.setCursorPos(1,1)
    monitor.setTextColor(colors.cyan)
    monitor.write("=== Auto Sorter v2 ===")
    monitor.setTextColor(colors.white)

    monitor.setCursorPos(1,3)
    monitor.write("Total processed: " .. stats.totalProcessed)

    monitor.setCursorPos(1,4)
    monitor.setTextColor(colors.orange)
    monitor.write("Fallback: " .. stats.fallbackCount)
    monitor.setTextColor(colors.white)

    monitor.setCursorPos(1,6)
    monitor.write("By category:")

    local y = 7
    for cat, count in pairs(stats.byCategory) do
        if count > 0 and y <= h-2 then
            monitor.setCursorPos(3, y)
            monitor.setTextColor(colors.lime)
            monitor.write(string.format("%-28s : %4d", cat:sub(1,28), count))
            monitor.setTextColor(colors.white)
            y = y + 1
        end
    end

    -- Frame
    monitor.setCursorPos(1,2)
    monitor.blit(string.rep("\131", w), string.rep("0", w), string.rep("f", w))
    monitor.setCursorPos(1,h)
    monitor.blit(string.rep("\143", w), string.rep("f", w), string.rep("0", w))
end

-- ────────────────────────────────────────────────
-- Main loop
-- ────────────────────────────────────────────────

drawUI()  -- initial draw

while true do
    local items = input.list()
    if not items or next(items) == nil then
        sleep(1)
        goto continue
    end

    for slot, item in pairs(items) do
        local moved = 0
        local category = ITEM_TO_CATEGORY[item.name]

        local targetChestName
        if category and CATEGORY_CHESTS[category] then
            targetChestName = "minecraft:hopper_" .. CATEGORY_CHESTS[category]
        else
            targetChestName = FALLBACK
        end

        local target = wrapPeripheral(targetChestName)
        if target then
            moved = input.pushItems(targetChestName, slot, item.count)
        end

        if moved > 0 then
            stats.totalProcessed = stats.totalProcessed + moved

            if targetChestName == FALLBACK then
                stats.fallbackCount = stats.fallbackCount + moved
            else
                local catKey = category or "Unknown"
                stats.byCategory[catKey] = (stats.byCategory[catKey] or 0) + moved
            end

            drawUI()  -- redraw every move (can be optimized later)
        end
    end

    ::continue::
    sleep(0.4)  -- don't overload the server
end
