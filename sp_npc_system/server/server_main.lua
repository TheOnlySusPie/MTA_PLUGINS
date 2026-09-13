-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Server Main (Resource Lifecycle, Tracking & Syncer Assignment)
-- ==============================================================================

ServerPeds = {}
ServerPeds.list = {}
ServerPeds.count = 0

function ServerPeds.init()
    outputServerLog("[SP NPC Rendszer] Szerver modul elindítva.")
    
    addEventHandler("onPlayerQuit", root, ServerPeds.onPlayerQuit)
    addEventHandler("onResourceStop", resourceRoot, ServerPeds.onStop)
end
addEventHandler("onResourceStart", resourceRoot, ServerPeds.init)

-- Amikor egy játékos lecsatlakozik, a hozzá kötött pedek syncerjét átadjuk a legközelebbi játékosnak
function ServerPeds.onPlayerQuit()
    local quittingPlayer = source
    for ped, data in pairs(ServerPeds.list) do
        if isElement(ped) then
            if data.creator == quittingPlayer then
                data.creator = nil
            end
        end
    end
end

-- Erőforrás leállításakor az összes NPC eltakarítása
function ServerPeds.onStop()
    for ped, _ in pairs(ServerPeds.list) do
        if isElement(ped) then
            destroyElement(ped)
        end
    end
    ServerPeds.list = {}
    ServerPeds.count = 0
    outputServerLog("[SP NPC Rendszer] Az összes Single Player NPC törölve.")
end

function ServerPeds.register(ped, creator, groupKey, zoneType)
    ServerPeds.list[ped] = {
        creator = creator,
        group = groupKey,
        zone = zoneType,
        spawnTime = getTickCount()
    }
    ServerPeds.count = ServerPeds.count + 1
end

function ServerPeds.unregister(ped)
    if ServerPeds.list[ped] then
        ServerPeds.list[ped] = nil
        ServerPeds.count = math.max(0, ServerPeds.count - 1)
    end
    if isElement(ped) then
        destroyElement(ped)
    end
end
