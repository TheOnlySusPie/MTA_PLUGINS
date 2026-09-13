-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- CTaskComplexSmartFleeEntity (100% GTA SA Smart Flee Implementation)
-- ==============================================================================

CTaskComplexSmartFleeEntity = setmetatable({}, { __index = CTaskComplex })
CTaskComplexSmartFleeEntity.__index = CTaskComplexSmartFleeEntity

function CTaskComplexSmartFleeEntity:new(threatEntity, safeDistance, scream)
    local instance = CTaskComplex.new(self, TASK_COMPLEX_SMART_FLEE_ENTITY)
    instance.threatEntity = threatEntity
    instance.safeDistance = safeDistance or 22.0
    instance.scream = (scream ~= false)
    instance.lastPosCheckTime = 0
    instance.lastScreamTime = 0
    instance.targetRot = nil
    instance.startTime = getTickCount()
    instance.maxFleeDuration = 18000 -- Max 18 másodpercig menekül, utána megnyugszik
    return instance
end

function CTaskComplexSmartFleeEntity:makeAbortable(ped)
    if isElement(ped) then
        setPedControlState(ped, "forwards", false)
        setPedControlState(ped, "sprint", false)
    end
    self.status = TASK_STATUS_ABORTED
    return true
end

function CTaskComplexSmartFleeEntity:process(ped)
    if not isElement(ped) or not isElement(self.threatEntity) then
        self:makeAbortable(ped)
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    local now = getTickCount()
    local px, py, pz = getElementPosition(ped)
    local tx, ty, tz = getElementPosition(self.threatEntity)
    
    local dist = MathUtils.getDistance2D(px, py, tx, ty)
    
    -- Ha elérte a biztonságos távolságot vagy lejárt a maximális menekülési idő
    if dist >= self.safeDistance or (now - self.startTime > self.maxFleeDuration) then
        self:makeAbortable(ped)
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    -- Időszakos sikítás / hanghatás (GTA SA ped scream)
    if self.scream and (now - self.lastScreamTime > 4000) then
        self.lastScreamTime = now
        -- MTA beépített hang / szöveg szimuláció
        if Config.Debug then
            outputChatBox("[NPC SIKÍTÁS] Segítség, meg akarnak ölni!", 255, 100, 100)
        end
    end
    
    -- Menekülési szög: A veszélyforrástól pontosan az ellenkező irányba
    local fleeAngle = MathUtils.findRotation(tx, ty, px, py)
    
    -- Akadályellenőrzés sprint közben
    local blocked = CollisionUtils.isObstacleInDirection(ped, 2.8, 0)
    if blocked then
        -- Ha fal van előtte, megtalálja a legszabadabb kitérési szöget
        fleeAngle = CollisionUtils.findClearAngle(ped)
    end
    
    -- Fordulás és sprintelés vezérlése
    local currentRot = getPedCameraRotation(ped) or getElementRotation(ped)
    local angleDiff = MathUtils.getAngleDifference(fleeAngle, currentRot)
    local step = math.min(math.abs(angleDiff), 20.0) * (angleDiff > 0 and 1 or -1)
    local newRot = MathUtils.normalizeAngle(currentRot + step)
    setPedCameraRotation(ped, newRot)
    setElementRotation(ped, 0, 0, newRot, "default", true)
    
    setPedControlState(ped, "forwards", true)
    setPedAnalogControlState(ped, "forwards", 1.0)
    setPedControlState(ped, "sprint", true)
    setPedControlState(ped, "walk", false)
    
    return self.status
end
