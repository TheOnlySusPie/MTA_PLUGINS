-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- CEventHandler (Event Processing & Decision Maker)
-- ==============================================================================

CEventHandler = {}
CEventHandler.__index = CEventHandler

function CEventHandler:new()
    local instance = setmetatable({}, self)
    return instance
end

-- ==============================================================================
-- 1. EVENT_DAMAGE: Amikor a pedet megtámadják (lövés, ütés, elütés)
-- ==============================================================================
function CEventHandler:handleDamage(ped, attacker, weapon, bodypart, loss)
    if not isElement(ped) or isPedDead(ped) then return end
    
    local taskMgr = PedManager.getTaskManager(ped)
    local stats = PedManager.getPedStats(ped)
    if not taskMgr or not stats then return end
    
    -- Ha az elkövető nem ismert entitás
    if not isElement(attacker) then
        attacker = localPlayer
    end
    
    local decision = stats.defaultDecisionMaker
    local fear = stats.fear or 50
    local temper = stats.temper or 50
    
    -- Rendőr (Cop): Mindig azonnal visszatámad és letartóztat/likvidál
    if decision == PedStats.DECISION_MAKER_COP then
        if Config.EnableCombat then
            taskMgr:setTask(CTaskComplexKillPedOnFoot:new(attacker), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
        end
        return
    end
    
    -- Bandatag vagy nagyon agresszív NPC (Temper >= Fear)
    if (decision == PedStats.DECISION_MAKER_RAND_TOUGH or temper > (fear + 10)) and Config.EnableCombat then
        -- 80% eséllyel visszatámad, 20% eséllyel menekül ha nagyon kevés a HP-ja
        local hp = getElementHealth(ped)
        if hp > 25 then
            taskMgr:setTask(CTaskComplexKillPedOnFoot:new(attacker), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
            return
        end
    end
    
    -- Gyáva / Normál polgár: Pánikszerű menekülés (Smart Flee)
    if Config.EnableFleeing then
        local safeDist = stats.fleeDistance or 20.0
        taskMgr:setTask(CTaskComplexSmartFleeEntity:new(attacker, safeDist, true), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
    end
end

-- ==============================================================================
-- 2. EVENT_GUN_AIMED_AT: Amikor fegyvert fognak a pedre
-- ==============================================================================
function CEventHandler:handleGunAimedAt(ped, aimer)
    if not isElement(ped) or isPedDead(ped) or not isElement(aimer) then return end
    
    local taskMgr = PedManager.getTaskManager(ped)
    local stats = PedManager.getPedStats(ped)
    if not taskMgr or not stats then return end
    
    -- Ha már harcol vagy menekül, ne szakítsuk meg
    if taskMgr:hasTaskType(TASK_COMPLEX_KILL_PED_ON_FOOT) or taskMgr:hasTaskType(TASK_COMPLEX_SMART_FLEE_ENTITY) then
        return
    end
    
    local decision = stats.defaultDecisionMaker
    
    -- Rendőr vagy keményfiú/bandatag: Visszacélzás és harc
    if (decision == PedStats.DECISION_MAKER_COP or decision == PedStats.DECISION_MAKER_RAND_TOUGH) and Config.EnableCombat then
        taskMgr:setTask(CTaskComplexKillPedOnFoot:new(aimer), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
        return
    end
    
    -- Normál vagy gyáva civil: Felteszi a kezét, majd elrohan
    if Config.EnableHandsUpOnAim and not taskMgr:hasTaskType(TASK_COMPLEX_HANDS_UP) then
        taskMgr:setTask(CTaskComplexHandsUp:new(aimer, math.random(3000, 5000)), TASK_PRIMARY_EVENT_RESPONSE_TEMP)
        
        -- A feltett kéz után azonnal meneküljön
        if Config.EnableFleeing then
            taskMgr:setTask(CTaskComplexSmartFleeEntity:new(aimer, stats.fleeDistance, true), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
        end
    end
end

-- ==============================================================================
-- 3. EVENT_SHOT_FIRED: Lövés dördül a közelben
-- ==============================================================================
function CEventHandler:handleShotFired(ped, shooter, shotX, shotY, shotZ)
    if not isElement(ped) or isPedDead(ped) then return end
    
    local taskMgr = PedManager.getTaskManager(ped)
    local stats = PedManager.getPedStats(ped)
    if not taskMgr or not stats then return end
    
    if taskMgr:hasTaskType(TASK_COMPLEX_KILL_PED_ON_FOOT) or taskMgr:hasTaskType(TASK_COMPLEX_SMART_FLEE_ENTITY) then
        return
    end
    
    local decision = stats.defaultDecisionMaker
    
    -- Rendőr a lövés forrása felé fordul és nyomoz / üldöz
    if decision == PedStats.DECISION_MAKER_COP and isElement(shooter) and Config.EnableCombat then
        taskMgr:setTask(CTaskComplexKillPedOnFoot:new(shooter), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
        return
    end
    
    -- Bandatagok felkészülnek vagy visszalőnek, ha az ellenség lőtt
    if decision == PedStats.DECISION_MAKER_RAND_TOUGH and isElement(shooter) and shooter == localPlayer and Config.EnableCombat then
        if math.random(1, 100) <= 50 then
            taskMgr:setTask(CTaskComplexKillPedOnFoot:new(shooter), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
            return
        end
    end
    
    -- Polgárok: Fejvédés (Cower) vagy menekülés
    if math.random(1, 100) <= 50 then
        taskMgr:setTask(CTaskComplexCower:new(math.random(3000, 6000)), TASK_PRIMARY_EVENT_RESPONSE_TEMP)
    else
        local threat = isElement(shooter) and shooter or localPlayer
        taskMgr:setTask(CTaskComplexSmartFleeEntity:new(threat, stats.fleeDistance, true), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
    end
end

-- ==============================================================================
-- 4. EVENT_POTENTIAL_GET_RUN_OVER: Jármű száguld a ped felé
-- ==============================================================================
function CEventHandler:handleVehicleNearMiss(ped, vehicle)
    if not isElement(ped) or isPedDead(ped) or not isElement(vehicle) then return end
    
    local taskMgr = PedManager.getTaskManager(ped)
    if not taskMgr then return end
    
    if taskMgr:hasTaskType(TASK_COMPLEX_DIVE_AWAY) then return end
    
    if Config.EnableCarDiveAway then
        taskMgr:setTask(CTaskComplexDiveAway:new(vehicle), TASK_PRIMARY_EVENT_RESPONSE_TEMP)
    end
end

-- ==============================================================================
-- 5. EVENT_VEHICLE_HORN: Autódudálásra adott reakció (Ökölrázás / Pánik)
-- ==============================================================================
function CEventHandler:handleVehicleHorn(ped, vehicle, driver)
    if not isElement(ped) or isPedDead(ped) or not isElement(vehicle) then return end
    if not Config.EnableHornReactions then return end
    
    local taskMgr = PedManager.getTaskManager(ped)
    local stats = PedManager.getPedStats(ped)
    if not taskMgr or not stats then return end
    
    -- Ha már harcol vagy menekül, ne szakítsuk meg
    if taskMgr:hasTaskType(TASK_COMPLEX_KILL_PED_ON_FOOT) or 
       taskMgr:hasTaskType(TASK_COMPLEX_SMART_FLEE_ENTITY) or 
       taskMgr:hasTaskType(TASK_COMPLEX_DIVE_AWAY) or
       taskMgr:hasTaskType(TASK_SIMPLE_SHAKE_FIST) then
        return
    end
    
    local decision = stats.defaultDecisionMaker
    local temper = stats.temper or 50
    local fear = stats.fear or 50
    
    -- Keményfiú / Bandatag / Agresszív ped: Dühös ökölrázás / bemutatás a sofőrnek
    if decision == PedStats.DECISION_MAKER_RAND_TOUGH or temper >= 55 then
        taskMgr:setTask(CTaskSimpleShakeFist:new(vehicle, 2200), TASK_PRIMARY_EVENT_RESPONSE_TEMP)
        return
    end
    
    -- Gyáva / Normál civil
    local px, py = getElementPosition(ped)
    local vx, vy = getElementPosition(vehicle)
    local dist = MathUtils.getDistance2D(px, py, vx, vy)
    
    if dist < 4.5 then
        -- Nagyon közel van: Elugrik
        taskMgr:setTask(CTaskComplexDiveAway:new(vehicle), TASK_PRIMARY_EVENT_RESPONSE_TEMP)
    else
        -- Kicsit távolabb: Felteszi a kezét vagy elszalad
        if math.random(1, 100) <= 50 then
            taskMgr:setTask(CTaskComplexHandsUp:new(vehicle, 2200), TASK_PRIMARY_EVENT_RESPONSE_TEMP)
        else
            taskMgr:setTask(CTaskComplexSmartFleeEntity:new(vehicle, stats.fleeDistance or 20.0, true), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
        end
    end
end

-- ==============================================================================
-- 6. EVENT_PED_BUMP: Játékossal vagy járművel való ütközés gyalog
-- ==============================================================================
function CEventHandler:handlePedBump(ped, bumper)
    if not isElement(ped) or isPedDead(ped) or not isElement(bumper) then return end
    if not Config.EnablePedBump then return end
    
    local taskMgr = PedManager.getTaskManager(ped)
    local stats = PedManager.getPedStats(ped)
    if not taskMgr or not stats then return end
    
    if taskMgr:hasTaskType(TASK_COMPLEX_KILL_PED_ON_FOOT) or 
       taskMgr:hasTaskType(TASK_COMPLEX_SMART_FLEE_ENTITY) or 
       taskMgr:hasTaskType(TASK_SIMPLE_SHAKE_FIST) then
        return
    end
    
    local temper = stats.temper or 50
    local decision = stats.defaultDecisionMaker
    
    if decision == PedStats.DECISION_MAKER_RAND_TOUGH or temper >= 60 then
        if math.random(1, 100) <= 50 then
            taskMgr:setTask(CTaskSimpleShakeFist:new(bumper, 1800), TASK_PRIMARY_EVENT_RESPONSE_TEMP)
        else
            taskMgr:setTask(CTaskSimpleBump:new(bumper, 1200), TASK_PRIMARY_EVENT_RESPONSE_TEMP)
        end
    else
        taskMgr:setTask(CTaskSimpleBump:new(bumper, 1200), TASK_PRIMARY_EVENT_RESPONSE_TEMP)
    end
end

-- ==============================================================================
-- 7. EVENT_GANG_HOSTILITY: Ellenséges bandatagok harca
-- ==============================================================================
function CEventHandler:handleGangHostility(ped1, ped2)
    if not isElement(ped1) or isPedDead(ped1) or not isElement(ped2) or isPedDead(ped2) then return end
    if not Config.EnableCombat or not Config.EnableGangWars then return end
    
    local task1 = PedManager.getTaskManager(ped1)
    local task2 = PedManager.getTaskManager(ped2)
    
    if task1 and not task1:hasTaskType(TASK_COMPLEX_KILL_PED_ON_FOOT) then
        task1:setTask(CTaskComplexKillPedOnFoot:new(ped2), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
    end
    if task2 and not task2:hasTaskType(TASK_COMPLEX_KILL_PED_ON_FOOT) then
        task2:setTask(CTaskComplexKillPedOnFoot:new(ped1), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
    end
end

-- ==============================================================================
-- 8. EVENT_COP_ALERT: Rendőr üldözés bűncselekmény vagy körözés esetén
-- ==============================================================================
function CEventHandler:handleCopAlert(copPed, criminal)
    if not isElement(copPed) or isPedDead(copPed) or not isElement(criminal) or isPedDead(criminal) then return end
    if not Config.EnableCombat or not Config.EnableCopPursuit then return end
    
    local taskMgr = PedManager.getTaskManager(copPed)
    if taskMgr and not taskMgr:hasTaskType(TASK_COMPLEX_KILL_PED_ON_FOOT) then
        taskMgr:setTask(CTaskComplexKillPedOnFoot:new(criminal), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
    end
end

