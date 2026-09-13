-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Reactive Tasks (Dive Away, Hands Up, Cower)
-- ==============================================================================

-- ==============================================================================
-- 1. CTaskComplexDiveAway (Elugrás száguldó jármű elől & Felállás - GTA SA CTaskComplexEvasiveDiveAndGetUp)
-- ==============================================================================
CTaskComplexDiveAway = setmetatable({}, { __index = CTaskComplex })
CTaskComplexDiveAway.__index = CTaskComplexDiveAway

function CTaskComplexDiveAway:new(vehicle)
    local instance = CTaskComplex.new(self, TASK_COMPLEX_DIVE_AWAY)
    instance.vehicle = vehicle
    instance.state = "INIT" -- INIT, DIVE, PAUSE, GET_UP, FINISHED
    instance.startTime = getTickCount()
    instance.diveDuration = 750
    instance.pauseDuration = 550
    instance.getUpDuration = 1700
    instance.startX = 0
    instance.startY = 0
    instance.startZ = 0
    instance.landX = 0
    instance.landY = 0
    instance.landZ = 0
    instance.diveAngle = 0
    return instance
end

function CTaskComplexDiveAway:makeAbortable(ped)
    if isElement(ped) then
        setPedAnimation(ped, false)
        setPedControlState(ped, "forwards", false)
        setPedControlState(ped, "sprint", false)
        setPedAnalogControlState(ped, "forwards", 0)
    end
    self.status = TASK_STATUS_ABORTED
    return true
end

function CTaskComplexDiveAway:process(ped)
    if not isElement(ped) or isPedDead(ped) then
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    local now = getTickCount()
    
    -- 1. FÁZIS: INICIALIZÁLÁS (Elugrási irány és érkezési pont kiszámítása)
    if self.state == "INIT" then
        local px, py, pz = getElementPosition(ped)
        local vx, vy, vz = px + 1, py, pz
        local vvx, vvy, vvz = 0, 0, 0
        
        if isElement(self.vehicle) then
            vx, vy, vz = getElementPosition(self.vehicle)
            vvx, vvy, vvz = getElementVelocity(self.vehicle)
        end
        
        -- Elugrási irány: merőlegesen az autó mozgásvonalára, az autótól távolodva
        local evX, evY = 0, 0
        local vSpeedSq = vvx * vvx + vvy * vvy
        if vSpeedSq > 0.001 then
            local perpLeftX = -vvy
            local perpLeftY = vvx
            local toPedX = px - vx
            local toPedY = py - vy
            
            -- Ha a ped a kocsi bal oldalán van, balra ugrik, ha jobbon, jobbra
            if (toPedX * perpLeftX + toPedY * perpLeftY) >= 0 then
                evX = perpLeftX
                evY = perpLeftY
            else
                evX = -perpLeftX
                evY = -perpLeftY
            end
        else
            evX = px - vx
            evY = py - vy
        end
        
        local len = math.sqrt(evX * evX + evY * evY)
        if len > 0.001 then
            evX = evX / len
            evY = evY / len
        else
            evX = 1
            evY = 0
        end
        
        local evadeAngle = MathUtils.findRotation(0, 0, evX, evY)
        local diveDist = 2.2 -- Eredeti GTA SA elugrási távolság
        
        -- Célpont kiszámítása
        local tX, tY = MathUtils.getPointInFront(px, py, evadeAngle, diveDist)
        local tZ = getGroundPosition(tX, tY, pz + 1.0)
        if not tZ or tZ <= 0 then tZ = pz end
        
        -- Falütközés ellenőrzése
        local hit = isLineOfSightClear(px, py, pz + 0.5, tX, tY, tZ + 0.5, true, false, false, true, false, false, false, ped)
        if not hit then
            -- Ha falba ugrana, az ellenkező oldalra ugrik
            evadeAngle = MathUtils.normalizeAngle(evadeAngle + 180)
            tX, tY = MathUtils.getPointInFront(px, py, evadeAngle, diveDist)
            tZ = getGroundPosition(tX, tY, pz + 1.0) or pz
        end
        
        self.startX, self.startY, self.startZ = px, py, pz
        self.landX, self.landY, self.landZ = tX, tY, tZ
        self.diveAngle = evadeAngle
        
        -- Ped befordítása az elugrás irányába
        setPedCameraRotation(ped, evadeAngle)
        setElementRotation(ped, 0, 0, evadeAngle, "default", true)
        
        -- Megállás és elugrás animáció indítása (freezeLastFrame = true, hogy a földön maradjon!)
        setPedControlState(ped, "forwards", false)
        setPedControlState(ped, "sprint", false)
        setPedAnalogControlState(ped, "forwards", 0)
        setPedAnimation(ped, "ped", "ev_dive", 1000, false, false, false, true)
        
        self.state = "DIVE"
        self.diveStartTime = now
        
    -- 2. FÁZIS: REPÜLÉS & FÖLDETÉRÉS (Fizikai koordináta sima mozgatása az érkezési pontra)
    elseif self.state == "DIVE" then
        local elapsed = now - self.diveStartTime
        local progress = math.min(1.0, elapsed / self.diveDuration)
        -- Természetes parabola lassulás (ease out quad)
        local ease = progress * (2 - progress)
        
        local cx = self.startX + (self.landX - self.startX) * ease
        local cy = self.startY + (self.landY - self.startY) * ease
        local cz = getGroundPosition(cx, cy, self.startZ + 1.2)
        if not cz or cz <= 0 then cz = self.startZ end
        
        setElementPosition(ped, cx, cy, cz)
        setElementRotation(ped, 0, 0, self.diveAngle, "default", true)
        
        if elapsed >= self.diveDuration then
            setElementPosition(ped, self.landX, self.landY, self.landZ)
            self.state = "PAUSE"
            self.pauseStartTime = now
        end
        
    -- 3. FÁZIS: FÖLDÖN FEKVÉS (GTA SA TaskSimplePause - lélegzetvétel a földön)
    elseif self.state == "PAUSE" then
        if now - self.pauseStartTime >= self.pauseDuration then
            self.state = "GET_UP"
            self.getUpStartTime = now
            -- Hivatalos GTA SA felállási animáció pontosan ott, ahol a földre esett!
            setPedAnimation(ped, "ped", "getup", self.getUpDuration, false, false, false, false)
        end
        
    -- 4. FÁZIS: FELÁLLÁS & SÉTA FOLYTATÁSA AZ ÚJ HELYRŐL (GTA SA TaskSimpleGetUp)
    elseif self.state == "GET_UP" then
        if now - self.getUpStartTime >= self.getUpDuration then
            setPedAnimation(ped, false)
            self.state = "FINISHED"
            self.status = TASK_STATUS_FINISHED
            
            -- Séta újrainicializálása a felállás koordinátájáról:
            -- keres egy új járdapontot a felállás helyétől, és onnan sétál tovább békésen!
            local tm = PedManager.getTaskManager(ped)
            if tm then
                tm:setTask(CTaskComplexWander:new(), TASK_PRIMARY_DEFAULT)
            end
        end
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

