-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Server Spawner (Entity Creation, Weapon Distribution & Culling)
-- ==============================================================================

ServerSpawner = {}

function ServerSpawner.init()
    addEvent("sp_npc:requestSpawn", true)
    addEventHandler("sp_npc:requestSpawn", resourceRoot, ServerSpawner.onSpawnRequest)
    
    addEvent("sp_npc:requestDespawn", true)
    addEventHandler("sp_npc:requestDespawn", resourceRoot, ServerSpawner.onDespawnRequest)
end
addEventHandler("onResourceStart", resourceRoot, ServerSpawner.init)

-- Kliens által kért NPC spawnolása
function ServerSpawner.onSpawnRequest(x, y, z, rot, skinId, groupKey, zoneType)
    local player = client
    if not isElement(player) then return end
    
    -- Globális és játékosonkénti határok ellenőrzése
    if ServerPeds.count >= Config.MaxGlobalPeds then
        return
    end
    
    -- Ped létrehozása
    local ped = createPed(skinId, x, y, z, rot)
    if not isElement(ped) then return end
    
    -- Megjelöljük, hogy ez az SP NPC rendszerhez tartozik
    setElementData(ped, "sp_npc:isSPPed", true)
    setElementData(ped, "sp_npc:groupKey", groupKey)
    setElementData(ped, "sp_npc:zoneType", zoneType)
    
    -- Sétastílus beállítása szerveroldalon is
    local walkStyle = PedStats.getWalkStyleForSkin(skinId)
    setPedWalkingStyle(ped, walkStyle)
    
    -- Fegyver kiosztása a csoport típusa alapján
    ServerSpawner.assignWeapons(ped, groupKey, skinId)
    
    -- Szinkronizáló játékos hozzárendelése (a kérő játékos a syncer, perzisztens módban)
    setElementSyncer(ped, player, true)
    
    -- Regisztráció a szerver listába
    ServerPeds.register(ped, player, groupKey, zoneType)
    
    -- Értesítjük a klienst a ped sikeres létrehozásáról
    triggerClientEvent(player, "sp_npc:clientRegisterPed", resourceRoot, ped)
end

-- Fegyverek kiosztása az eredeti GTA SA arányok alapján
function ServerSpawner.assignWeapons(ped, groupKey, skinId)
    local stats = PedStats.getStatsForSkin(skinId)
    local decision = stats.defaultDecisionMaker
    
    -- 1. Rendőrök (100% fegyver: 9mm Pisztoly vagy Gumibot)
    if decision == PedStats.DECISION_MAKER_COP or groupKey == "COPS" then
        if math.random(1, 100) <= 80 then
            giveWeapon(ped, 22, 500, true) -- 9mm Pistol
        else
            giveWeapon(ped, 3, 1, true)   -- Nightstick
        end
        return
    end
    
    -- 2. Bandatagok (65% fegyver: 9mm, Micro-SMG, Tec-9, Kés, Baseball ütő)
    local isGang = (groupKey == "BALLAS" or groupKey == "FAMILIES" or groupKey == "LSV" or 
                    groupKey == "SFR" or groupKey == "DNB" or groupKey == "VMAFF" or 
                    groupKey == "TRIADS" or groupKey == "VLA" or groupKey == "DEALERS")
                    
    if isGang then
        if math.random(1, 100) <= Config.GangWeaponChance then
            local weapons = { 22, 28, 32, 4, 5 } -- Pistol, Micro Uzi, Tec-9, Knife, Bat
            local chosenWeapon = weapons[math.random(1, #weapons)]
            giveWeapon(ped, chosenWeapon, 400, true)
        end
        return
    end
    
    -- 3. Agresszív civilek / Keményfiúk (kis eséllyel kés vagy pisztoly)
    if decision == PedStats.DECISION_MAKER_RAND_TOUGH then
        if math.random(1, 100) <= Config.CivilianWeaponChance then
            giveWeapon(ped, (math.random(1, 2) == 1) and 4 or 22, 150, true)
        end
    end
end

-- Kliens által kért culling / despawn
function ServerSpawner.onDespawnRequest(ped)
    if isElement(ped) and getElementData(ped, "sp_npc:isSPPed") then
        ServerPeds.unregister(ped)
    end
end
