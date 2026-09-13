-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Server Emergency Services (Ambulance, Fire Truck, Police & Revive Logic)
-- ==============================================================================

ServerEmergency = {}
ServerEmergency.vehicles = {}

function ServerEmergency.init()
    addEvent(sp_npc:requestEmergencyDispatch, true)
    addEventHandler(sp_npc:requestEmergencyDispatch, resourceRoot, ServerEmergency.onDispatch)
    
    addEvent(sp_npc:revivePed, true)
    addEventHandler(sp_npc:revivePed, resourceRoot, ServerEmergency.revivePed)
    
    addEvent(sp_npc:extinguishVehicle, true)
    addEventHandler(sp_npc:extinguishVehicle, resourceRoot, ServerEmergency.extinguishVehicle)
    
    addEvent(sp_npc:playerBusted, true)
    addEventHandler(sp_npc:playerBusted, resourceRoot, ServerEmergency.onPlayerBusted)
    
    outputServerLog([SP NPC Rendszer] Segelyszolgalatok (Mento, Tuzolto, Rendorseg) modul elinditva.)
end
addEventHandler(onResourceStart, resourceRoot, ServerEmergency.init)

-- Veszhelyzeti egyseg kikuldese
function ServerEmergency.onDispatch(serviceType, incX, incY, incZ, targetElement, spawnX, spawnY, spawnZ, spawnRot)
    local player = client
    if not isElement(player) then return end
    
    if ServerPeds.count >= Config.MaxGlobalPeds then
        return
    end
    
    local vehModel = 596
    local skin1 = 280
    local skin2 = 280
    local weapon = 22
    local ammo = 300
    local groupKey = COPS
    
    if serviceType == MEDIC then
        vehModel = 416
        skin1 = 274
        skin2 = 275
        weapon = nil
        groupKey = MEDIC
    elseif serviceType == FIRE then
        vehModel = 407
        skin1 = 277
        skin2 = 277
        weapon = 42 -- Porolto (Fire Extinguisher)
        ammo = 999
        groupKey = FIRE
    elseif serviceType == POLICE then
        vehModel = 596
        skin1 = 280
        skin2 = 280
        weapon = 22 -- 9mm Pistol
        ammo = 300
        groupKey = COPS
    end
    
    -- Jarmu letrehozasa szirenaval
    local veh = createVehicle(vehModel, spawnX, spawnY, spawnZ + 0.4, 0, 0, spawnRot)
    if not isElement(veh) then return end
    
    setVehicleSirensOn(veh, true)
    setElementData(veh, sp_npc:isEmergencyVehicle, true)
    table.insert(ServerEmergency.vehicles, { veh = veh, spawnTime = getTickCount() })
    
    -- Szemelyzet elhelyezese a jarmu mellett (kiszallt egyseg szimulalasa)
    local rad = math.rad(spawnRot)
    local leftX = spawnX - math.cos(rad) * 1.8
    local leftY = spawnY - math.sin(rad) * 1.8
    local rightX = spawnX + math.cos(rad) * 1.8
    local rightY = spawnY + math.sin(rad) * 1.8
    
    local ped1 = createPed(skin1, leftX, leftY, spawnZ, spawnRot)
    local ped2 = createPed(skin2, rightX, rightY, spawnZ, spawnRot)
    
    if not isElement(ped1) then
        destroyElement(veh)
        return
    end
    
    -- Ped 1 (Vezeto / Fo egyseg)
    setElementData(ped1, sp_npc:isSPPed, true)
    setElementData(ped1, sp_npc:groupKey, groupKey)
    setElementData(ped1, sp_npc:zoneType, EMERGENCY)
    setPedWalkingStyle(ped1, PedStats.getWalkStyleForSkin(skin1))
    if weapon then giveWeapon(ped1, weapon, ammo, true) end
    setElementSyncer(ped1, player, true)
    ServerPeds.register(ped1, player, groupKey, EMERGENCY)
    
    triggerClientEvent(player, sp_npc:clientRegisterPed, resourceRoot, ped1)
    triggerClientEvent(player, sp_npc:clientAssignEmergencyTask, resourceRoot, ped1, serviceType, targetElement, incX, incY, incZ, false)
    
    -- Ped 2 (Tars / Masodlagos egyseg)
    if isElement(ped2) then
        setElementData(ped2, sp_npc:isSPPed, true)
        setElementData(ped2, sp_npc:groupKey, groupKey)
        setElementData(ped2, sp_npc:zoneType, EMERGENCY)
        setPedWalkingStyle(ped2, PedStats.getWalkStyleForSkin(skin2))
        if weapon then giveWeapon(ped2, weapon, ammo, true) end
        setElementSyncer(ped2, player, true)
        ServerPeds.register(ped2, player, groupKey, EMERGENCY)
        
        triggerClientEvent(player, sp_npc:clientRegisterPed, resourceRoot, ped2)
        local isAssistant = (serviceType == MEDIC)
        triggerClientEvent(player, sp_npc:clientAssignEmergencyTask, resourceRoot, ped2, serviceType, targetElement, incX, incY, incZ, isAssistant)
    end
    
    -- Jarmu takaritasa 90 masodperc mulva, ha nincs benne jatekos
    setTimer(function()
        if isElement(veh) then
            local occupants = getVehicleOccupants(veh)
            local hasRealPlayer = false
            if occupants then
                for _, occ in pairs(occupants) do
                    if getElementType(occ) == player then
                        hasRealPlayer = true
                        break
                    end
                end
            end
            if not hasRealPlayer then
                destroyElement(veh)
            end
        end
    end, 90000, 1)
end

-- Halott NPC ujraelesztese sikeres CPR utan
function ServerEmergency.revivePed(corpsePed)
    if not isElement(corpsePed) then return end
    
    local x, y, z = getElementPosition(corpsePed)
    local _, _, rot = getElementRotation(corpsePed)
    local skinId = getElementModel(corpsePed)
    local groupKey = getElementData(corpsePed, sp_npc:groupKey) or CIVMALE
    local zoneType = getElementData(corpsePed, sp_npc:zoneType) or COMMERCIAL
    
    -- Regi holttest torlese
    ServerPeds.unregister(corpsePed)
    
    -- Uj elo ped letrehozasa a halott helyen
    local revivedPed = createPed(skinId, x, y, z, rot)
    if not isElement(revivedPed) then return end
    
    setElementData(revivedPed, sp_npc:isSPPed, true)
    setElementData(revivedPed, sp_npc:groupKey, groupKey)
    setElementData(revivedPed, sp_npc:zoneType, zoneType)
    setElementHealth(revivedPed, 65.0)
    
    local walkStyle = PedStats.getWalkStyleForSkin(skinId)
    setPedWalkingStyle(revivedPed, walkStyle)
    
    local syncer = client or getElementsByType(player)[1]
    if syncer then
        setElementSyncer(revivedPed, syncer, true)
    end
    
    ServerPeds.register(revivedPed, syncer, groupKey, zoneType)
    
    -- Ertesitjuk a klienseket az ujraeledesrol
    triggerClientEvent(root, sp_npc:clientOnPedRevived, resourceRoot, revivedPed)
end

-- Ego jarmu eloltasa es megmentese a robbanastol
function ServerEmergency.extinguishVehicle(vehicle)
    if not isElement(vehicle) then return end
    fixVehicle(vehicle)
    setElementHealth(vehicle, 550.0)
end

-- Jatekos letartoztatasa (Busted)
function ServerEmergency.onPlayerBusted()
    local player = client
    if not isElement(player) then return end
    
    takeAllWeapons(player)
    setPlayerWantedLevel(player, 0)
    
    -- Esetleges birsag (100 dollar)
    if getPlayerMoney(player) and getPlayerMoney(player) >= 100 then
        takePlayerMoney(player, 100)
    end
end
