-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Reactive Tasks (Dive Away, Hands Up, Cower)
-- ==============================================================================

-- ==============================================================================
-- 1. CTaskComplexDiveAway (Elugrás száguldó jármű elől)
-- ==============================================================================
CTaskComplexDiveAway = setmetatable({}, { __index = CTaskComplex })
CTaskComplexDiveAway.__index = CTaskComplexDiveAway

function CTaskComplexDiveAway:new(vehicle)
    local instance = CTaskComplex.new(self, TASK_COMPLEX_DIVE_AWAY)
    instance.vehicle = vehicle
    instance.startTime = getTickCount()
    instance.duration = 1400 -- Animáció időtartama
    instance.initiated = false
    return instance
end

function CTaskComplexDiveAway:makeAbortable(ped)
    if isElement(ped) then
        setPedAnimation(ped, false)
        setPedControlState(ped, "forwards", false)
        setPedControlState(ped, "sprint", false)
    end
    self.status = TASK_STATUS_ABORTED
    return true
end

function CTaskComplexDiveAway:process(ped)
    if not isElement(ped) then
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    local now = getTickCount()
    if not self.initiated then
        self.initiated = true
        self.startTime = now
        
        -- Kiszámoljuk az elugrás irányát (merőlegesen a jármű mozgásvektorára)
        local dodgeDir = (math.random(1, 2) == 1) and "ev_dive" or "dodge_front"
        setPedAnimation(ped, "ped", dodgeDir, 1200, false, false, false, false)
    end
    
    if now - self.startTime >= self.duration then
        setPedAnimation(ped, false)
        self.status = TASK_STATUS_FINISHED
    end
    
    return self.status
end

-- ==============================================================================
-- 2. CTaskComplexHandsUp (Feltett kezek fegyveres célzáskor)
-- ==============================================================================
CTaskComplexHandsUp = setmetatable({}, { __index = CTaskComplex })
CTaskComplexHandsUp.__index = CTaskComplexHandsUp

function CTaskComplexHandsUp:new(aimerEntity, duration)
    local instance = CTaskComplex.new(self, TASK_COMPLEX_HANDS_UP)
    instance.aimerEntity = aimerEntity
    instance.duration = duration or math.random(3500, 6000)
    instance.startTime = getTickCount()
    instance.initiated = false
    return instance
end

function CTaskComplexHandsUp:makeAbortable(ped)
    if isElement(ped) then
        setPedAnimation(ped, false)
    end
    self.status = TASK_STATUS_ABORTED
    return true
end

function CTaskComplexHandsUp:process(ped)
    if not isElement(ped) then
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    local now = getTickCount()
    
    if not self.initiated then
        self.initiated = true
        self.startTime = now
        
        setPedControlState(ped, "forwards", false)
        setPedControlState(ped, "sprint", false)
        setPedControlState(ped, "fire", false)
        
        -- Szembefordulás a fegyvert fogó játékossal
        if isElement(self.aimerEntity) then
            local px, py = getElementPosition(ped)
            local ax, ay = getElementPosition(self.aimerEntity)
            local rot = MathUtils.findRotation(px, py, ax, ay)
            setPedCameraRotation(ped, rot)
            setElementRotation(ped, 0, 0, rot, "default", true)
        end
        
        setPedAnimation(ped, "ped", "handsup", -1, false, false, false, false)
    end
    
    if now - self.startTime >= self.duration then
        setPedAnimation(ped, false)
        self.status = TASK_STATUS_FINISHED
    end
    
    return self.status
end

-- ==============================================================================
-- 3. CTaskComplexCower (Kuporgás és fejvédés lövöldözéskor)
-- ==============================================================================
CTaskComplexCower = setmetatable({}, { __index = CTaskComplex })
CTaskComplexCower.__index = CTaskComplexCower

function CTaskComplexCower:new(duration)
    local instance = CTaskComplex.new(self, TASK_COMPLEX_COWER)
    instance.duration = duration or math.random(4000, 7000)
    instance.startTime = getTickCount()
    instance.initiated = false
    return instance
end

function CTaskComplexCower:makeAbortable(ped)
    if isElement(ped) then
        setPedAnimation(ped, false)
    end
    self.status = TASK_STATUS_ABORTED
    return true
end

function CTaskComplexCower:process(ped)
    if not isElement(ped) then
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    local now = getTickCount()
    
    if not self.initiated then
        self.initiated = true
        self.startTime = now
        setPedControlState(ped, "forwards", false)
        setPedControlState(ped, "sprint", false)
        setPedControlState(ped, "walk", false)
        setPedAnimation(ped, "ped", "cower", -1, false, false, false, false)
    end
    
    if now - self.startTime >= self.duration then
        setPedAnimation(ped, false)
        self.status = TASK_STATUS_FINISHED
    end
    
    return self.status
end

-- ==============================================================================
-- 4. CTaskSimpleShakeFist (Középső ujj / ökölrázás düh esetén - GTA SA CTaskSimpleShakeFist)
-- ==============================================================================
CTaskSimpleShakeFist = setmetatable({}, { __index = CTaskComplex })
CTaskSimpleShakeFist.__index = CTaskSimpleShakeFist

function CTaskSimpleShakeFist:new(targetEntity, duration)
    local instance = CTaskComplex.new(self, TASK_SIMPLE_SHAKE_FIST)
    instance.targetEntity = targetEntity
    instance.duration = duration or 2200
    instance.startTime = getTickCount()
    instance.initiated = false
    instance.animName = (math.random(1, 100) <= 60) and "fucku" or "gesture_damn"
    return instance
end

function CTaskSimpleShakeFist:makeAbortable(ped)
    if isElement(ped) then
        setPedAnimation(ped, false)
        setPedControlState(ped, "forwards", false)
        setPedControlState(ped, "sprint", false)
        setPedAnalogControlState(ped, "forwards", 0)
    end
    self.status = TASK_STATUS_ABORTED
    return true
end

function CTaskSimpleShakeFist:process(ped)
    if not isElement(ped) then
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    local now = getTickCount()
    
    if not self.initiated then
        self.initiated = true
        self.startTime = now
        
        -- Megállítjuk a mozgást
        setPedControlState(ped, "forwards", false)
        setPedControlState(ped, "sprint", false)
        setPedControlState(ped, "walk", false)
        setPedAnalogControlState(ped, "forwards", 0)
        
        -- Szembefordulás a célponttal (jármű vagy játékos)
        if isElement(self.targetEntity) then
            local px, py = getElementPosition(ped)
            local tx, ty = getElementPosition(self.targetEntity)
            local rot = MathUtils.findRotation(px, py, tx, ty)
            setPedCameraRotation(ped, rot)
            setElementRotation(ped, 0, 0, rot, "default", true)
        end
        
        -- Eredeti GTA SA fucku / gesture_damn animáció
        setPedAnimation(ped, "ped", self.animName, self.duration, false, false, false, false)
    end
    
    if now - self.startTime >= self.duration then
        setPedAnimation(ped, false)
        self.status = TASK_STATUS_FINISHED
    end
    
    return self.status
end

-- ==============================================================================
-- 5. CTaskSimpleBump (Ütközés / Meglökés reakció - GTA SA CEventPotentialWalkIntoPed)
-- ==============================================================================
CTaskSimpleBump = setmetatable({}, { __index = CTaskComplex })
CTaskSimpleBump.__index = CTaskSimpleBump

function CTaskSimpleBump:new(bumperEntity, duration)
    local instance = CTaskComplex.new(self, TASK_SIMPLE_STAND_STILL)
    instance.bumperEntity = bumperEntity
    instance.duration = duration or 1200
    instance.startTime = getTickCount()
    instance.initiated = false
    return instance
end

function CTaskSimpleBump:makeAbortable(ped)
    if isElement(ped) then
        setPedAnimation(ped, false)
    end
    self.status = TASK_STATUS_ABORTED
    return true
end

function CTaskSimpleBump:process(ped)
    if not isElement(ped) then
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    local now = getTickCount()
    
    if not self.initiated then
        self.initiated = true
        self.startTime = now
        
        setPedControlState(ped, "forwards", false)
        setPedControlState(ped, "sprint", false)
        setPedAnalogControlState(ped, "forwards", 0)
        
        if isElement(self.bumperEntity) then
            local px, py = getElementPosition(ped)
            local bx, by = getElementPosition(self.bumperEntity)
            local rot = MathUtils.findRotation(px, py, bx, by)
            setPedCameraRotation(ped, rot)
            setElementRotation(ped, 0, 0, rot, "default", true)
        end
        
        -- Dühös vagy meglepett reakció animáció
        local anim = (math.random(1, 2) == 1) and "facanger" or "endchat_01"
        setPedAnimation(ped, "ped", anim, self.duration, false, false, false, false)
    end
    
    if now - self.startTime >= self.duration then
        setPedAnimation(ped, false)
        self.status = TASK_STATUS_FINISHED
    end
    
    return self.status
end

