-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Client Main (PedManager, Syncer Controller & AI Loop)
-- ==============================================================================

PedManager = {}
PedManager.managedPeds = {}
PedManager.eventHandler = nil

function PedManager.init()
    PedManager.eventHandler = CEventHandler:new()
    EventScanner.init()
    PathManager.init()
    
    -- Események regisztrálása
    addEventHandler("onClientRender", root, PedManager.onRender)
    addEventHandler("onClientElementStreamIn", root, PedManager.onStreamIn)
    addEventHandler("onClientElementStreamOut", root, PedManager.onStreamOut)
    addEventHandler("onClientElementDestroy", root, PedManager.onDestroy)
    
    -- AI Loop időzítő (50 ms = 20 FPS AI tick sima mozgáshoz)
    setTimer(PedManager.pulseAI, Config.AITickInterval, 0)
    
    -- Szerver esemény, amikor új pedet kapunk
    addEvent("sp_npc:clientRegisterPed", true)
    addEventHandler("sp_npc:clientRegisterPed", resourceRoot, PedManager.registerPed)
    
    -- Újraélesztett ped esemény kezelése
    addEvent("sp_npc:clientOnPedRevived", true)
    addEventHandler("sp_npc:clientOnPedRevived", resourceRoot, function(ped)
        if not isElement(ped) then return end
        PedManager.registerPed(ped)
        setPedAnimation(ped, "ped", "getup", 2200, false, false, false, false)
        setTimer(function()
            if isElement(ped) and not isPedDead(ped) then
                setPedAnimation(ped, false)
                local tm = PedManager.getTaskManager(ped)
                if tm then
                    tm:setTask(CTaskComplexWander:new(), TASK_PRIMARY_DEFAULT)
                end
            end
        end, 2200, 1)
    end)
    
    -- Megkeressük a már létező pedeket csatlakozáskor
    local existingPeds = getElementsByType("ped", root, true)
    for _, ped in ipairs(existingPeds) do
        if getElementData(ped, "sp_npc:isSPPed") then
            PedManager.registerPed(ped)
        end
    end
    
    outputChatBox("#00FF88[SP NPC Rendszer] #FFFFFFKliens modul sikeresen betöltve!", 255, 255, 255, true)
end
addEventHandler("onClientResourceStart", resourceRoot, PedManager.init)

-- Új ped regisztrálása a helyi AI rendszerbe
function PedManager.registerPed(ped)
    if not isElement(ped) or PedManager.managedPeds[ped] then return end
    
    local skinId = getElementModel(ped)
    local stats = PedStats.getStatsForSkin(skinId)
    local taskMgr = CTaskManager:new(ped)
    
    -- Kezdeti feladat: Alapértelmezett séta (Wander)
    taskMgr:setTask(CTaskComplexWander:new(), TASK_PRIMARY_DEFAULT)
    
    -- Sétastílus beállítása a skin alapján (hogy élethűen sétáljon előre)
    local walkStyle = PedStats.getWalkStyleForSkin(skinId)
    setPedWalkingStyle(ped, walkStyle)
    
    local _, _, rot = getElementRotation(ped)
    setPedCameraRotation(ped, rot)
    
    -- Opcionális blip a teszteléshez
    local blip = nil
    if Config.ShowPedBlips then
        blip = createBlipAttachedTo(ped, 0, 1, 100, 200, 255, 200)
    end
    
    PedManager.managedPeds[ped] = {
        taskMgr = taskMgr,
        stats = stats,
        skinId = skinId,
        blip = blip
    }
end

function PedManager.onStreamIn()
    if getElementType(source) == "ped" and getElementData(source, "sp_npc:isSPPed") then
        PedManager.registerPed(source)
    end
end

function PedManager.onStreamOut()
    if PedManager.managedPeds[source] then
        if isElement(PedManager.managedPeds[source].blip) then
            destroyElement(PedManager.managedPeds[source].blip)
        end
        PedManager.managedPeds[source] = nil
    end
end

function PedManager.onDestroy()
    if PedManager.managedPeds[source] then
        if isElement(PedManager.managedPeds[source].blip) then
            destroyElement(PedManager.managedPeds[source].blip)
        end
        PedManager.managedPeds[source] = nil
    end
end

function PedManager.isManagedPed(ped)
    return (PedManager.managedPeds[ped] ~= nil)
end

function PedManager.getTaskManager(ped)
    if PedManager.managedPeds[ped] then
        return PedManager.managedPeds[ped].taskMgr
    end
    return nil
end

function PedManager.getPedStats(ped)
    if PedManager.managedPeds[ped] then
        return PedManager.managedPeds[ped].stats
    end
    return nil
end

function PedManager.getAllActivePeds()
    return PedManager.managedPeds
end

function PedManager.getActivePedCount()
    local count = 0
    for ped, _ in pairs(PedManager.managedPeds) do
        if isElement(ped) and not isPedDead(ped) then
            count = count + 1
        end
    end
    return count
end

-- Fő AI ciklus (Syncer alapú futtatás)
function PedManager.pulseAI()
    -- Scanner és Spawner pulzálás
    EventScanner.pulse()
    ClientSpawner.pulse()
    EmergencyManager.pulse()
    
    local px, py, pz = getElementPosition(localPlayer)
    
    for ped, data in pairs(PedManager.managedPeds) do
        if isElement(ped) then
            if isPedDead(ped) then
                -- Ha meghalt, takarítás
                data.taskMgr:clearTasks()
            else
                -- Syncer ellenőrzés: ha ez a kliens a syncer, vagy ő az egyetlen játékos a szerveren
                local isMySyncer = isElementSyncer(ped)
                if isMySyncer == nil or isMySyncer == true or #getElementsByType("player") <= 1 then
                    data.taskMgr:process()
                end
                
                -- Ambient Look-At (GTA SA IK LookAt fejfordítás az elhaladó játékos felé)
                if Config.EnableLookAt and not data.taskMgr:hasTaskType(TASK_COMPLEX_KILL_PED_ON_FOOT) and not data.taskMgr:hasTaskType(TASK_COMPLEX_SMART_FLEE_ENTITY) then
                    local pedX, pedY, pedZ = getElementPosition(ped)
                    local dist = MathUtils.getDistance2D(px, py, pedX, pedY)
                    local now = getTickCount()
                    data.lastLookAtCheck = data.lastLookAtCheck or 0
                    
                    if now - data.lastLookAtCheck > 800 then
                        data.lastLookAtCheck = now
                        if dist >= 1.8 and dist <= 6.5 and math.abs(pz - pedZ) <= 2.5 and MathUtils.isPointInPedFOV(ped, px, py, 75.0) then
                            setPedLookAt(ped, px, py, pz + 0.6, 2200, 250, localPlayer)
                        end
                    end
                end
            end
        else
            PedManager.managedPeds[ped] = nil
        end
    end
end

-- Debug megjelenítés (mindig aktív, ha Config.Debug = true)
function PedManager.onRender()
    if not Config.Debug then return end
    
    local px, py, pz = getElementPosition(localPlayer)
    local activeCount = 0
    
    for ped, data in pairs(PedManager.managedPeds) do
        if isElement(ped) and not isPedDead(ped) then
            activeCount = activeCount + 1
            local x, y, z = getElementPosition(ped)
            local dist = MathUtils.getDistance3D(px, py, pz, x, y, z)
            
            if dist < 28.0 then
                local sx, sy = getScreenFromWorldPosition(x, y, z + 1.15)
                if sx and sy then
                    local activeTask, idx = data.taskMgr:getActiveTask()
                    local tType = activeTask and activeTask:getTaskType() or 0
                    local taskName = TaskNames and TaskNames[tType] or ("Type " .. tType)
                    local color = (tType == TASK_COMPLEX_DIVE_AWAY) and tocolor(255, 100, 0, 240)
                               or (tType == TASK_COMPLEX_KILL_PED_ON_FOOT) and tocolor(255, 40, 40, 240)
                               or (tType == TASK_COMPLEX_SMART_FLEE_ENTITY) and tocolor(255, 200, 0, 240)
                               or (tType == TASK_COMPLEX_MEDIC_CPR) and tocolor(0, 220, 255, 240)
                               or (tType == TASK_COMPLEX_EXTINGUISH_FIRE) and tocolor(255, 150, 0, 240)
                               or (tType == TASK_COMPLEX_POLICE_ARREST) and tocolor(50, 150, 255, 240)
                               or tocolor(0, 255, 140, 230)
                    
                    local info = string.format("[%s]\nHP: %.0f | Fear: %d | Temp: %d", taskName, getElementHealth(ped), data.stats.fear or 0, data.stats.temper or 0)
                    dxDrawText(info, sx - 100, sy - 25, sx + 100, sy + 25, color, 1.05, "default-bold", "center", "center")
                end
                
                -- Vizuális vonal a célcsomóponthoz séta közben
                local activeTask = data.taskMgr:getActiveTask()
                if activeTask and activeTask.targetNode then
                    dxDrawLine3D(x, y, z, activeTask.targetNode.x, activeTask.targetNode.y, activeTask.targetNode.z + 0.3, tocolor(0, 255, 120, 130), 2)
                end
            end
        end
    end
    
    -- Debug HUD információs panel a bal oldalon
    local zoneName, zoneType = ZonesData.getZoneAtPosition(px, py)
    local stars = getPlayerWantedLevel() or 0
    local hudText = string.format("[SP NPC RENDSZER - DEBUG AKTÍV]\nAktív NPC-k: %d / %d\nZóna: %s (%s)\nKörözés: %d csillag", activeCount, Config.MaxPedsPerPlayer, zoneName or "Ismeretlen", zoneType or "None", stars)
    dxDrawRectangle(15, 195, 240, 75, tocolor(0, 0, 0, 150))
    dxDrawText(hudText, 25, 202, 250, 265, tocolor(0, 255, 200, 230), 1.0, "default-bold", "left", "top")
end
