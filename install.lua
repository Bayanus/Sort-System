-- Sort-System installer
-- Downloads files from GitHub
-- CC:Tweaked compatible

local BASE_URL = "https://raw.githubusercontent.com/Bayanus/Sort-System/main/"

local FILES = {
  { remote = "sort.lua", localf = "sort.lua", overwrite = true },
  { remote = "category_chests.lua", localf = "category_chests.lua", overwrite = true },
  --{ remote = "startup.lua", localf = "startup.lua", overwrite = true },

  -- configs (do NOT overwrite by default)
  { remote = "filtClean.json", localf = "filtClean.json", overwrite = false },
}

-- =========================
-- UTILS
-- =========================

local function download(remote, localf)
  local url = BASE_URL .. remote
  print("Downloading " .. remote)

  local res = http.get(url)
  if not res then
    error("Failed to download: " .. remote)
  end

  local data = res.readAll()
  res.close()

  local f = fs.open(localf, "w")
  f.write(data)
  f.close()
end

-- =========================
-- INSTALL
-- =========================

print("=== Sort-System installer ===")

if not http then
  error("HTTP API disabled. Enable it in CC:Tweaked config.")
end

for _, file in ipairs(FILES) do
  if fs.exists(file.localf) and not file.overwrite then
    print("Skipping existing config: " .. file.localf)
  else
    download(file.remote, file.localf)
    print("Installed: " .. file.localf)
  end
end

print("Installation complete.")
print("Rebooting in 3 seconds...")

sleep(3)
os.reboot()
