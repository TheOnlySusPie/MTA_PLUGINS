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

-- Debug megjelenítés
function PedManager.onRender()
    if not Config.Debug then return end
    
    local px, py, pz = getElementPosition(localPlayer)
    for ped, data in pairs(PedManager.managedPeds) do
        if isElement(ped) and not isPedDead(ped) then
            local x, y, z = getElementPosition(ped)
            local dist = MathUtils.getDistance3D(px, py, pz, x, y, z)
            if dist < 25.0 then
                local sx, sy = getScreenFromWorldPosition(x, y, z + 1.1)
                if sx and sy then
                    local activeTask, idx = data.taskMgr:getActiveTask()
                    local taskName = activeTask and ("Slot " .. idx .. ": Type " .. activeTask:getTaskType()) or "None"
                    local info = string.format("Task: %s\nFear: %d | Temper: %d\nHP: %.0f", taskName, data.stats.fear or 0, data.stats.temper or 0, getElementHealth(ped))
                    dxDrawText(info, sx - 80, sy - 20, sx + 80, sy + 20, tocolor(255, 255, 255, 220), 1, "default-bold", "center", "center")
                end
            end
        end
    end
end
