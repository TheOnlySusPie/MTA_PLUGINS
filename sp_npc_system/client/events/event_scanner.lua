-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Event Scanner (Aim Detection, Gunshots, Vehicle Near-Miss, Social Chat)
-- ==============================================================================

EventScanner = {}
EventScanner.lastScanTime = 0

function EventScanner.init()
    -- Fegyvertűz esemény elkapása
    addEventHandler("onClientPlayerWeaponFire", root, EventScanner.onWeaponFire)
    
    -- Sérülés esemény elkapása a pedeken
    addEventHandler("onClientPedDamage", root, EventScanner.onPedDamage)
end

-- Amikor fegyverrel lőnek
function EventScanner.onWeaponFire(weapon, ammo, clip, hitX, hitY, hitZ, hitElement)
    local shooter = source
    local sx, sy, sz = getElementPosition(shooter)
    
    -- Végigmegyünk az aktív NPC-ken, és ha hallótávolságban vannak (35m), reagálnak
    local peds = PedManager.getAllActivePeds()
    for ped, data in pairs(peds) do
        if isElement(ped) and not isPedDead(ped) then
            local px, py, pz = getElementPosition(ped)
            local dist = MathUtils.getDistance3D(sx, sy, sz, px, py, pz)
            if dist <= 35.0 then
                PedManager.eventHandler:handleShotFired(ped, shooter, sx, sy, sz)
            end
        end
    end
end

-- Amikor egy NPC sebződik
function EventScanner.onPedDamage(attacker, weapon, bodypart, loss)
    local ped = source
    if PedManager.isManagedPed(ped) then
        PedManager.eventHandler:handleDamage(ped, attacker, weapon, bodypart, loss)
    end
end

-- Időszakos pásztázó ciklus (250 ms-onként fut)
function EventScanner.pulse()
    local now = getTickCount()
    if now - EventScanner.lastScanTime < Config.ScannerInterval then
        return
    end
    EventScanner.lastScanTime = now
    
    -- 1. Fegyveres célzás ellenőrzése a helyi játékos részéről
    local targetedElement = getPedTarget(localPlayer)
    if targetedElement and getElementType(targetedElement) == "ped" then
        if PedManager.isManagedPed(targetedElement) then
            local currentTask = getPedTask(localPlayer, "secondary", 0) or ""
            local weapon = getPedWeapon(localPlayer)
            if weapon and weapon >= 22 and weapon <= 38 then
                PedManager.eventHandler:handleGunAimedAt(targetedElement, localPlayer)
            end
        end
    end
    
    -- 2. Jármű gázolás-veszély, dudálás és beszélgetések pásztázása
    local peds = PedManager.getAllActivePeds()
    local pedList = {}
    for p, _ in pairs(peds) do
        if isElement(p) and not isPedDead(p) then
            table.insert(pedList, p)
        end
    end
    
    local vehicles = getElementsByType("vehicle", root, true)
    
    -- Játékos járművének és dudájának ellenőrzése
    local playerVeh = getPedOccupiedVehicle(localPlayer)
    local isPlayerHonking = false
    if playerVeh and getVehicleController(playerVeh) == localPlayer then
        if getPedControlState(localPlayer, "horn") or getKeyState("h") then
            isPlayerHonking = true
        end
    end
    
    for _, ped in ipairs(pedList) do
        local px, py, pz = getElementPosition(ped)
        
        -- Gázolásveszély gyors járműveknél (< 10m és sebesség > 0.2)
        if Config.EnableCarDiveAway then
            for _, veh in ipairs(vehicles) do
                local vx, vy, vz = getElementPosition(veh)
                local dist = MathUtils.getDistance2D(px, py, vx, vy)
                if dist < 9.0 and math.abs(pz - vz) < 2.0 then
                    local sx, sy, sz = getElementVelocity(veh)
                    local speed = math.sqrt(sx * sx + sy * sy + sz * sz)
                    if speed > 0.22 then
                        PedManager.eventHandler:handleVehicleNearMiss(ped, veh)
                        break
                    end
                end
            end
        end
        
        -- Dudálásra való reakció (GTA SA CEventVehicleHorn)
        if isPlayerHonking and Config.EnableHornReactions then
            local vx, vy, vz = getElementPosition(playerVeh)
            local dist = MathUtils.getDistance2D(px, py, vx, vy)
            if dist <= 13.0 and math.abs(pz - vz) <= 2.5 then
                local _, _, vRot = getElementRotation(playerVeh)
                local angleToPed = MathUtils.findRotation(vx, vy, px, py)
                local diff = math.abs(MathUtils.getAngleDifference(angleToPed, vRot))
                if diff <= 70.0 then
                    PedManager.eventHandler:handleVehicleHorn(ped, playerVeh, localPlayer)
                end
            end
        end
    end
    
    -- 3. Játékossal való ütközés gyalog (GTA SA CEventPotentialWalkIntoPed)
    if Config.EnablePedBump and not isPedInVehicle(localPlayer) then
        local lx, ly, lz = getElementPosition(localPlayer)
        local lvx, lvy, lvz = getElementVelocity(localPlayer)
        local playerSpeedSq = lvx * lvx + lvy * lvy + lvz * lvz
        if playerSpeedSq > 0.002 then
            for _, ped in ipairs(pedList) do
                local px, py, pz = getElementPosition(ped)
                local dist = MathUtils.getDistance3D(lx, ly, lz, px, py, pz)
                if dist <= 1.1 and math.abs(lz - pz) <= 1.0 then
                    PedManager.eventHandler:handlePedBump(ped, localPlayer)
                end
            end
        end
    end
    
    -- 4. Ellenséges bandák közötti háború (Acquaintance HATE)
    if Config.EnableGangWars and #pedList >= 2 then
        for i = 1, #pedList - 1 do
            local p1 = pedList[i]
            local g1 = PedStats.getPedGang(getElementModel(p1))
            if g1 and g1 ~= "COP" then
                local p1x, p1y, p1z = getElementPosition(p1)
                for j = i + 1, #pedList do
                    local p2 = pedList[j]
                    local g2 = PedStats.getPedGang(getElementModel(p2))
                    if g2 and PedStats.areGangsEnemies(g1, g2) then
                        local p2x, p2y, p2z = getElementPosition(p2)
                        local dist = MathUtils.getDistance2D(p1x, p1y, p2x, p2y)
                        if dist <= 18.0 and math.abs(p1z - p2z) < 3.0 then
                            if CollisionUtils.hasClearLineOfSight(p1x, p1y, p1z + 0.6, p2x, p2y, p2z + 0.6, p1) then
                                PedManager.eventHandler:handleGangHostility(p1, p2)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- 5. Rendőri reakció körözésre vagy fegyveres támadásra (GTA SA Cop AI)
    if Config.EnableCopPursuit then
        local wantedLevel = getPlayerWantedLevel()
        local isAiming = getPedControlState(localPlayer, "aim_weapon")
        local isFiring = getPedControlState(localPlayer, "fire")
        local weapon = getPedWeapon(localPlayer)
        local isViolent = (isAiming or isFiring) and (weapon and weapon >= 22 and weapon <= 38)
        
        if wantedLevel > 0 or isViolent then
            local lx, ly, lz = getElementPosition(localPlayer)
            for _, ped in ipairs(pedList) do
                local gang = PedStats.getPedGang(getElementModel(ped))
                if gang == "COP" then
                    local cx, cy, cz = getElementPosition(ped)
                    local dist = MathUtils.getDistance2D(cx, cy, lx, ly)
                    if dist <= 25.0 and math.abs(cz - lz) < 3.5 then
                        if MathUtils.isPointInPedFOV(ped, lx, ly, 95.0) and CollisionUtils.hasClearLineOfSight(cx, cy, cz + 0.6, lx, ly, lz + 0.6, ped) then
                            PedManager.eventHandler:handleCopAlert(ped, localPlayer)
                        end
                    end
                end
            end
        end
    end
    
    -- 6. Spontán utcai beszélgetések (két békésen sétáló NPC között)
    if Config.EnablePedChat and #pedList >= 2 then
        for i = 1, #pedList - 1 do
            local p1 = pedList[i]
            local task1 = PedManager.getTaskManager(p1)
            
            if task1 and task1:hasTaskType(TASK_COMPLEX_WANDER) then
                local p1x, p1y, p1z = getElementPosition(p1)
                
                for j = i + 1, #pedList do
                    local p2 = pedList[j]
                    local task2 = PedManager.getTaskManager(p2)
                    
                    if task2 and task2:hasTaskType(TASK_COMPLEX_WANDER) then
                        local p2x, p2y, p2z = getElementPosition(p2)
                        local dist = MathUtils.getDistance2D(p1x, p1y, p2x, p2y)
                        
                        if dist <= 2.2 and math.abs(p1z - p2z) < 1.0 then
                            -- 12% eséllyel megállnak beszélgetni
                            if math.random(1, 100) <= 12 then
                                task1:setTask(CTaskComplexChat:new(p2, true), TASK_PRIMARY_DEFAULT)
                                task2:setTask(CTaskComplexChat:new(p1, false), TASK_PRIMARY_DEFAULT)
                            end
                        end
                    end
                end
            end
        end
    end
end

