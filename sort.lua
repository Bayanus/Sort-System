-- sort.lua with monitor stats (English only, bigger font, recent items)

-- ────────────────────────────────────────────────
-- CONFIG
-- ────────────────────────────────────────────────
local INPUT_CHEST_NAME  = "minecraft:chest_6"   -- input chest
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

local recentMoves = {}       -- Last 8 moves: "Oak Log → Logs (x64)"

-- ────────────────────────────────────────────────
-- Find monitor automatically
-- ────────────────────────────────────────────────

local monitor = peripheral.find("monitor")
if not monitor then
    printError("No monitor found nearby!")
    return
end

-- Setup monitor: BIGGER FONT
monitor.setTextScale(1.0)   -- Bigger: 1.0 (fits ~26x19 on 5x3 monitor)
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
-- Category → chest mapping
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

-- Get nice item name
local function getItemName(item)
    return item.displayName or (item.name:gsub("^[^:]+:", ""):gsub("_", " "))
end

-- ────────────────────────────────────────────────
-- Draw beautiful monitor UI
-- ────────────────────────────────────────────────

local function drawUI()
    monitor.clear()
    monitor.setCursorPos(1,1)
    monitor.setTextColor(colors.cyan)
    monitor.write("=== AUTO SORTER v2.1 ===")
    monitor.setTextColor(colors.white)

    -- Totals
    monitor.setCursorPos(1,3)
    monitor.write("Total: " .. stats.totalProcessed)
    monitor.setCursorPos(1,4)
    monitor.setTextColor(colors.orange)
    monitor.write("Fallback: " .. stats.fallbackCount)
    monitor.setTextColor(colors.white)

    -- Recent moves
    monitor.setCursorPos(1,6)
    monitor.setTextColor(colors.yellow)
    monitor.write("Recent moves:")
    monitor.setTextColor(colors.white)
    local y = 7
    for i, moveStr in ipairs(recentMoves) do
        if y > h - 4 then break end  -- Leave space for categories
        monitor.setCursorPos(2, y)
        monitor.setTextColor(colors.lime)
        monitor.write(moveStr)
        monitor.setTextColor(colors.white)
        y = y + 1
    end

    -- Top categories (sorted by count)
    local yCatStart = math.max(y + 1, 14)
    monitor.setCursorPos(1, yCatStart)
    monitor.setTextColor(colors.aqua)
    monitor.write("Top categories:")
    monitor.setTextColor(colors.white)

    -- Sort and show top 6
    local sortedCats = {}
    for cat, cnt in pairs(stats.byCategory) do
        table.insert(sortedCats, {name=cat, cnt=cnt})
    end
    table.sort(sortedCats, function(a, b) return a.cnt > b.cnt end)

    y = yCatStart + 1
    for i = 1, math.min(6, #sortedCats) do
        if y > h - 1 then break end
        local cat = sortedCats[i].name
        local cnt = sortedCats[i].cnt
        monitor.setCursorPos(3, y)
        monitor.setTextColor(colors.lime)
        monitor.write(string.format("%-22s: %d", cat:sub(1,22), cnt))
        y = y + 1
    end

    -- Bottom frame
    monitor.setCursorPos(1, h)
    monitor.setTextColor(colors.gray)
    monitor.write(string.rep("-", w))
end

-- ────────────────────────────────────────────────
-- Main loop
-- ────────────────────────────────────────────────

local lastRedraw = 0
drawUI()  -- initial

while true do
    local items = input and input.list() or {}
    if next(items) == nil then
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

            local itemName = getItemName(item)
            local catDisplay = category or "Fallback"
            local moveStr = string.format("%s → %s (x%d)", itemName, catDisplay, moved)

            -- Add to recent
            table.insert(recentMoves, 1, moveStr)
            if #recentMoves > 8 then
                table.remove(recentMoves)
            end

            -- Update stats
            if targetChestName == FALLBACK then
                stats.fallbackCount = stats.fallbackCount + moved
            else
                stats.byCategory[category] = (stats.byCategory[category] or 0) + moved
            end

            -- Redraw (throttled)
            local now = os.clock()
            if now - lastRedraw > 0.5 then  -- Update every 0.5s max
                drawUI()
                lastRedraw = now
            end
        end
    end

    ::continue::
    sleep(0.3)
end
