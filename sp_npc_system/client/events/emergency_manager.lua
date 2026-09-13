-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Emergency Services & Wanted Level Manager (Police, Medic, Fire, Crime)
-- ==============================================================================

EmergencyManager = {}
EmergencyManager.lastDispatchTime = {}
EmergencyManager.lastCrimeTime = 0
EmergencyManager.lastDecayCheck = 0
EmergencyManager.activeCorpseDispatches = {}

function EmergencyManager.init()
    if not Config.EnableEmergencyServices then return end
    
    -- Események elkapása
    addEventHandler("onClientPedWasted", root, EmergencyManager.onPedWasted)
    addEventHandler("onClientVehicleDamage", root, EmergencyManager.onVehicleDamage)
    addEventHandler("onClientRender", root, EmergencyManager.renderWantedUI)
    
    -- Busted esemény
    addEvent("sp_npc:onPlayerBusted", true)
    addEventHandler("sp_npc:onPlayerBusted", localPlayer, EmergencyManager.handlePlayerBusted)
    
    -- Szerver válasz az egység megérkezésére
    addEvent("sp_npc:clientAssignEmergencyTask", true)
    addEventHandler("sp_npc:clientAssignEmergencyTask", resourceRoot, EmergencyManager.assignEmergencyTask)
end
addEventHandler("onClientResourceStart", resourceRoot, EmergencyManager.init)

-- Időszakos ellenőrzés (Scannerből hívva)
function EmergencyManager.pulse()
    if not Config.EnableEmergencyServices then return end
    
    local now = getTickCount()
    
    -- 1. Körözési szint automatikus csökkenése (Decay), ha a játékos elrejtőzik
    if Config.EnableWantedStars and now - EmergencyManager.lastDecayCheck >= 5000 then
        EmergencyManager.lastDecayCheck = now
        local currentStars = getPlayerWantedLevel()
        if currentStars and currentStars > 0 then
            -- Ha 35 másodpercig nem követett el bűnt és nincs zsaru a közelben
            if now - EmergencyManager.lastCrimeTime >= 35000 then
                local copsNear = EmergencyManager.isCopNearPlayer(30.0)
                if not copsNear then
                    setPlayerWantedLevel(math.max(0, currentStars - 1))
                    EmergencyManager.lastCrimeTime = now - 15000
                end
            end
        end
    end
    
    -- 2. Égő / füstölő járművek keresése a tűzoltóknak
    if Config.EnableFireService and EmergencyManager.canDispatch("FIRE") then
        local px, py, pz = getElementPosition(localPlayer)
        local vehicles = getElementsByType("vehicle", root, true)
        for _, veh in ipairs(vehicles) do
            local vx, vy, vz = getElementPosition(veh)
            local dist = MathUtils.getDistance2D(px, py, vx, vy)
            if dist <= 60.0 and math.abs(pz - vz) <= 5.0 then
                local hp = getElementHealth(veh)
                if hp <= 255 and hp > 0 then
                    EmergencyManager.dispatch("FIRE", vx, vy, vz, veh)
                    break
                end
            end
        end
    end
    
    -- 3. Rendőrségi erősítés küldése, ha körözés van
    if Config.EnablePoliceDispatch and EmergencyManager.canDispatch("POLICE") then
        local stars = getPlayerWantedLevel()
        if stars and stars >= 1 then
            local copsNear = EmergencyManager.isCopNearPlayer(40.0)
            if not copsNear then
                local px, py, pz = getElementPosition(localPlayer)
                EmergencyManager.dispatch("POLICE", px, py, pz, localPlayer)
            end
        end
    end
end

-- Amikor egy NPC meghal (Mentő hívása)
function EmergencyManager.onPedWasted(killer, weapon, bodypart)
    local ped = source
    if not isElement(ped) then return end
    
    -- Körözés növelése, ha a játékos ölte meg
    if killer == localPlayer and Config.EnableWantedStars then
        EmergencyManager.reportCrime("KILL_PED")
    end
    
    -- Mentőautó küldése a holttesthez
    if Config.EnableAmbulanceService and EmergencyManager.canDispatch("MEDIC") then
        local px, py, pz = getElementPosition(ped)
        local lx, ly, lz = getElementPosition(localPlayer)
        local dist = MathUtils.getDistance2D(px, py, lx, ly)
        
        -- Csak ha a játékos közelében történt (< 75m)
        if dist <= 75.0 and not EmergencyManager.activeCorpseDispatches[ped] then
            EmergencyManager.activeCorpseDispatches[ped] = true
            setTimer(function()
                if isElement(ped) then
                    EmergencyManager.dispatch("MEDIC", px, py, pz, ped)
                end
            end, 3000, 1)
        end
    end
end

-- Amikor egy jármű sebződik
function EmergencyManager.onVehicleDamage(attacker, weapon, loss)
    if attacker == localPlayer and Config.EnableWantedStars then
        if loss > 150 then
            EmergencyManager.reportCrime("VEHICLE_DAMAGE")
        end
    end
end

-- Bűncselekmény jelentése és körözési csillagok növelése
function EmergencyManager.reportCrime(crimeType)
    local now = getTickCount()
    EmergencyManager.lastCrimeTime = now
    
    local currentStars = getPlayerWantedLevel() or 0
    local newStars = currentStars
    
    if crimeType == "GUNFIRE" then
        if currentStars < 1 then newStars = 1 end
    elseif crimeType == "ASSAULT" then
        if currentStars < 1 then newStars = 1 end
    elseif crimeType == "VEHICLE_DAMAGE" then
        if currentStars < 1 then newStars = 1 end
    elseif crimeType == "KILL_PED" then
        newStars = math.min(6, math.max(1, currentStars + 1))
    elseif crimeType == "ATTACK_COP" then
        newStars = math.min(6, math.max(3, currentStars + 2))
    end
    
    if newStars ~= currentStars then
        setPlayerWantedLevel(newStars)
        outputChatBox(string.format("#FF3333[Rendőrség] #FFFFFFKörözési szint megnövelve: %d csillag!", newStars), 255, 255, 255, true)
    end
end

-- Ellenőrzi, hogy küldhető-e az adott típusú segélyegység
function EmergencyManager.canDispatch(serviceType)
    local now = getTickCount()
    local lastTime = EmergencyManager.lastDispatchTime[serviceType] or 0
    return (now - lastTime >= (Config.EmergencyCooldown or 12000))
end

-- Kiszámol egy megfelelő megjelenési pontot a járműnek a helyszíntől 38-52 méterre
function EmergencyManager.findEmergencySpawnPoint(x, y, z)
    local angle = math.random() * math.pi * 2
    local dist = math.random(38, 52)
    local sx = x + math.cos(angle) * dist
    local sy = y + math.sin(angle) * dist
    local sz = z + 0.5
    local rot = MathUtils.findRotation(sx, sy, x, y)
    return sx, sy, sz, rot
end

-- Segélyegység kérése a szervertől
function EmergencyManager.dispatch(serviceType, x, y, z, targetElement)
    EmergencyManager.lastDispatchTime[serviceType] = getTickCount()
    local sx, sy, sz, srot = EmergencyManager.findEmergencySpawnPoint(x, y, z)
    triggerServerEvent("sp_npc:requestEmergencyDispatch", resourceRoot, serviceType, x, y, z, targetElement, sx, sy, sz, srot)
end

-- Szerver által létrehozott segélyegység ped feladatainak beállítása
function EmergencyManager.assignEmergencyTask(ped, serviceType, targetElement, x, y, z, isAssistant)
    if not isElement(ped) then return end
    
    local taskMgr = PedManager.getTaskManager(ped)
    if not taskMgr then return end
    
    if serviceType == "MEDIC" and isElement(targetElement) then
        taskMgr:setTask(CTaskComplexMedicCPR:new(targetElement, isAssistant), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
    elseif serviceType == "FIRE" then
        taskMgr:setTask(CTaskComplexExtinguishFire:new(targetElement, x, y, z), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
    elseif serviceType == "POLICE" and isElement(targetElement) then
        local stars = getPlayerWantedLevel() or 1
        if stars <= 1 then
            taskMgr:setTask(CTaskComplexPoliceArrest:new(targetElement), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
        else
            taskMgr:setTask(CTaskComplexKillPedOnFoot:new(targetElement), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
        end
    end
end

-- Ellenőrzi, hogy van-e rendőr a játékos közelében
function EmergencyManager.isCopNearPlayer(radius)
    local px, py, pz = getElementPosition(localPlayer)
    local peds = PedManager.getAllActivePeds()
    for ped, _ in pairs(peds) do
        if isElement(ped) and not isPedDead(ped) then
            local model = getElementModel(ped)
            local gang = PedStats.getPedGang(model)
            if gang == "COP" then
                local cx, cy, cz = getElementPosition(ped)
                local dist = MathUtils.getDistance2D(px, py, cx, cy)
                if dist <= radius and math.abs(pz - cz) < 6.0 then
                    return true
                end
            end
        end
    end
    return false
end

-- Játékos letartóztatása (Busted)
function EmergencyManager.handlePlayerBusted(copPed)
    setPlayerWantedLevel(0)
    fadeCamera(false, 1.5, 0, 0, 0)
    outputChatBox("#FF2222[LEKAPCSOLVA] #FFFFFFElkaptak a rendőrök! (Busted)", 255, 255, 255, true)
    
    setTimer(function()
        fadeCamera(true, 1.5)
        -- Elkobozzuk a fegyvereket békésen
        takeAllWeapons(localPlayer)
    end, 3000, 1)
end

-- Körözési csillagok HUD megjelenítése (ha aktív)
function EmergencyManager.renderWantedUI()
    if not Config.EnableWantedStars then return end
    local stars = getPlayerWantedLevel()
    if not stars or stars == 0 then return end
    
    local sw, sh = guiGetScreenSize()
    local starText = string.rep("★ ", stars)
    dxDrawText(starText, sw - 220, 45, sw - 20, 75, tocolor(255, 215, 0, 240), 2.2, "default-bold", "right", "center")
end
