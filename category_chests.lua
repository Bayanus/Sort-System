-- category_chests.lua
-- Maps JSON category names -> chest numbers
-- Only edit this file to change sorting destinations

return {

  -- =========================
  -- MANUAL / FALLBACK
  -- =========================
  ManualSorting = 45,

  -- =========================
  -- BLOCKS
  -- =========================

  OverworldNatural = 8,
  NetherNatural    = 10,
  EndNatural       = 12,

  BuildingFull     = 5,
  BuildingShaped   = 6,

  WoodLogs         = 3,
  WoodPlanks       = 4,

  FunctionalBlocks = 7,

  -- =========================
  -- EQUIPMENT
  -- =========================

  MeleeWeapons = 14,
  RangedWeapons = 15,
  Ammo = 16,
  Armor = 17,
  Tools = 18,

  -- =========================
  -- RESOURCES
  -- =========================

  Iron     = 19,
  Gold     = 20,
  Diamond  = 21,
  Emerald  = 22,
  Copper  = 23,
  Coal    = 24,
  OtherOres = 25,

  -- =========================
  -- CRAFT
  -- =========================

  Materials     = 1,
  
  -- =========================
  -- FOOD
  -- =========================

  RawCrops   = 26,
  RawMeat    = 27,
  RawMeals  = 28,

  CookedCrops  = 29,
  CookedMeat   = 30,
  CookedMeals  = 31,

  -- =========================
  -- MOB DROPS
  -- =========================

  MobFlesh = 45,
  MobDrops = 2,

  -- =========================
  -- MECHANISMS
  -- =========================

  Redstone = 35,
  Rails = 34,

  PolyfactoryMaterials = 33,
  PolyfactoryMachines = 32,

  -- =========================
  -- MAGIC
  -- =========================

  EnchantedBooks = 34,
  Potions = 35,
  Alchemy = 36,

  -- =========================
  -- PLANTS
  -- =========================

  Saplings = 38,
  Seeds = 39,
  Bamboo = 40,
  Cactus = 41,
  Wheat = 42,
  SugarCane = 43,
  Flowers = 44,
}
