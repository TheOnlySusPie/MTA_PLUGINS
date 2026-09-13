-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Client Popcycle Spawner & Culling Manager
-- ==============================================================================

ClientSpawner = {}
ClientSpawner.lastSpawnCheck = 0
ClientSpawner.lastCullCheck = 0

function ClientSpawner.pulse()
    local now = getTickCount()
    
    -- 1. Spawn ellenőrzés
    if now - ClientSpawner.lastSpawnCheck >= Config.SpawnCheckInterval then
        ClientSpawner.lastSpawnCheck = now
        ClientSpawner.checkAndSpawn()
    end
    
    -- 2. Culling / Despawn ellenőrzés
    if now - ClientSpawner.lastCullCheck >= Config.DespawnCheckInterval then
        ClientSpawner.lastCullCheck = now
        ClientSpawner.checkAndCull()
    end
end

-- Ellenőrzi a játékos körüli populációt és szükség esetén új NPC-t kér a szervertől
function ClientSpawner.checkAndSpawn()
    local myPedsCount = PedManager.getActivePedCount()
    if myPedsCount >= Config.MaxPedsPerPlayer then
        return
    end
    
    local px, py, pz = getElementPosition(localPlayer)
    local getTimeHours, _ = getTime()
    local isNight = (getTimeHours >= 22 or getTimeHours <= 5)
    
    local zoneType, cityCode, zoneName = ZonesData.getZoneInfo(px, py, pz)
    local skinId, groupKey = PopcycleData.getRandomSkin(zoneType, cityCode, isNight)
    
    -- Biztonságos pozíció keresése a játékos körül (30m - 65m)
    local spawnX, spawnY, spawnZ, rot = ClientSpawner.findSafeSpawnPoint(px, py, pz)
    if spawnX then
        -- Kérjük a szervertől a ped létrehozását
        triggerServerEvent("sp_npc:requestSpawn", resourceRoot, spawnX, spawnY, spawnZ, rot, skinId, groupKey, zoneType)
    end
end

-- Biztonságos talajpont keresése (elsődlegesen GTA SA útvonal-csomópontok alapján)
function ClientSpawner.findSafeSpawnPoint(playerX, playerY, playerZ)
    -- 1. Ha be van töltve a GTA SA járdacsomópont-hálózat, az alapján spawnolunk közvetlenül a járdára
    if PathManager and PathManager.isLoaded then
        local areaID = PathManager.getAreaID(playerX, playerY)
        local areaList = { areaID }
        local localX = (playerX + 3000) % 750
        local localY = (playerY + 3000) % 750
        if localX < 80 and (areaID % 8) > 0 then table.insert(areaList, areaID - 1) end
        if localX > 670 and (areaID % 8) < 7 then table.insert(areaList, areaID + 1) end
        if localY < 80 and areaID >= 8 then table.insert(areaList, areaID - 8) end
        if localY > 670 and areaID <= 55 then table.insert(areaList, areaID + 8) end
        
        local candidates = {}
        for _, aID in ipairs(areaList) do
            local nodes = vehicleNodes and vehicleNodes[aID]
            if nodes then
                for _, node in pairs(nodes) do
                    local dist = MathUtils.getDistance2D(playerX, playerY, node.x, node.y)
                    if dist >= Config.SpawnRadiusMin and dist <= Config.SpawnRadiusMax then
                        if math.abs(node.z - playerZ) < 7.0 then
                            table.insert(candidates, node)
                            if #candidates >= 30 then break end
                        end
                    end
                end
            end
            if #candidates >= 30 then break end
        end
        
        if #candidates > 0 then
            local chosen = candidates[math.random(1, #candidates)]
            local gz = CollisionUtils.getGroundZ(chosen.x, chosen.y, chosen.z)
            return chosen.x, chosen.y, gz + 0.95, math.random(0, 360)
        end
    end

    -- 2. Fallback: Raycast keresés a játékos körül
    local maxAttempts = 5
    for attempt = 1, maxAttempts do
        local randomAngle = math.random(0, 360)
        local randomDist = math.random(Config.SpawnRadiusMin, Config.SpawnRadiusMax)
        
        local cx, cy = MathUtils.getPointInFront(playerX, playerY, randomAngle, randomDist)
        local groundZ = CollisionUtils.getGroundZ(cx, cy, playerZ)
        
        -- Ellenőrizzük, hogy a magasságkülönbség reális-e
        if groundZ and math.abs(groundZ - playerZ) < 8.0 and groundZ > -10.0 then
            local isBlocked = processLineOfSight(
                cx, cy, groundZ + 0.5,
                cx, cy, groundZ + 1.5,
                true, true, false, true, true, false, false, false
            )
            
            if not isBlocked then
                local spawnRot = math.random(0, 360)
                return cx, cy, groundZ + 0.95, spawnRot
            end
        end
    end
    return nil
end

-- Ellenőrzi a távoli pedeket és törli azokat, akik túl messze kerültek
function ClientSpawner.checkAndCull()
    local px, py, pz = getElementPosition(localPlayer)
    local camRot = getCameraMatrix()
    local peds = PedManager.getAllActivePeds()
    
    for ped, data in pairs(peds) do
        if isElement(ped) then
            local x, y, z = getElementPosition(ped)
            local dist = MathUtils.getDistance2D(px, py, x, y)
            
            -- Ha 85m-nél messzebb van, azonnal törlődik
            if dist > Config.DespawnRadius then
                triggerServerEvent("sp_npc:requestDespawn", resourceRoot, ped)
            -- Ha 55m-nél messzebb van és a játékos háttal áll neki
            elseif dist > Config.BehindPlayerDespawnDist then
                local isBehind = not MathUtils.isPointInFieldOfView(px, py, getPedCameraRotation(localPlayer), x, y, 90)
                if isBehind then
                    triggerServerEvent("sp_npc:requestDespawn", resourceRoot, ped)
                end
            end
        end
    end
end
