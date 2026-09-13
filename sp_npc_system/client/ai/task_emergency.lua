-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Emergency AI Tasks (Medic CPR, Fire Extinguishing, Police Arrest)
-- ==============================================================================

-- ==============================================================================
-- 1. CTaskComplexMedicCPR (Mentős újraélesztés - GTA SA TaskSimpleGiveCPR)
-- ==============================================================================
CTaskComplexMedicCPR = setmetatable({}, { __index = CTaskComplex })
CTaskComplexMedicCPR.__index = CTaskComplexMedicCPR

function CTaskComplexMedicCPR:new(targetCorpse, isAssistant)
    local instance = CTaskComplex.new(self, TASK_COMPLEX_MEDIC_CPR)
    instance.targetCorpse = targetCorpse
    instance.isAssistant = isAssistant or false
    instance.state = "APPROACH" -- APPROACH, CPR, FINISHED
    instance.cprStartTime = 0
    instance.cprDuration = 7000
    instance.isRevived = false
    return instance
end

function CTaskComplexMedicCPR:makeAbortable(ped)
    if isElement(ped) then
        setPedControlState(ped, "forwards", false)
        setPedControlState(ped, "sprint", false)
        setPedAnalogControlState(ped, "forwards", 0)
        setPedAnimation(ped, false)
    end
    self.status = TASK_STATUS_ABORTED
    return true
end

function CTaskComplexMedicCPR:process(ped)
    if not isElement(ped) or isPedDead(ped) then
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    if not isElement(self.targetCorpse) then
        self:makeAbortable(ped)
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    local now = getTickCount()
    local px, py, pz = getElementPosition(ped)
    local tx, ty, tz = getElementPosition(self.targetCorpse)
    local dist = MathUtils.getDistance2D(px, py, tx, ty)
    local stopDist = self.isAssistant and 2.8 or 1.6
    
    if self.state == "APPROACH" then
        if dist > stopDist then
            -- Futás a sérülthöz
            local targetRot = MathUtils.findRotation(px, py, tx, ty)
            setPedCameraRotation(ped, targetRot)
            setElementRotation(ped, 0, 0, targetRot, "default", true)
            setPedControlState(ped, "forwards", true)
            setPedControlState(ped, "sprint", true)
            setPedAnalogControlState(ped, "forwards", 1.0)
        else
            -- Megérkezett: szembefordulás és CPR indítása
            setPedControlState(ped, "forwards", false)
            setPedControlState(ped, "sprint", false)
            setPedAnalogControlState(ped, "forwards", 0)
            
            local targetRot = MathUtils.findRotation(px, py, tx, ty)
            setPedCameraRotation(ped, targetRot)
            setElementRotation(ped, 0, 0, targetRot, "default", true)
            
            self.state = "CPR"
            self.cprStartTime = now
            
            if self.isAssistant then
                -- Asszisztens figyeli a sérültet és a terepet
                setPedLookAt(ped, tx, ty, tz + 0.3, 7000)
                setPedAnimation(ped, "dealer", "dealer_idle", 7000, true, false, false, false)
            else
                -- Eredeti GTA SA medic CPR animáció
                setPedAnimation(ped, "medic", "cpr", self.cprDuration, false, false, false, false)
            end
        end
        
    elseif self.state == "CPR" then
        setPedControlState(ped, "forwards", false)
        setPedControlState(ped, "sprint", false)
        setPedAnalogControlState(ped, "forwards", 0)
        
        if now - self.cprStartTime >= self.cprDuration then
            setPedAnimation(ped, false)
            
            if not self.isAssistant then
                -- Újraélesztési esély kiszámítása (65%)
                local roll = math.random(1, 100)
                if roll <= (Config.MedicCPRReviveChance or 65) then
                    self.isRevived = true
                    triggerServerEvent("sp_npc:revivePed", resourceRoot, self.targetCorpse)
                else
                    -- Nem sikerült: felállás és dühös gesztus
                    setPedAnimation(ped, "ped", "facanger", 1800, false, false, false, false)
                end
            end
            
            self.state = "FINISHED"
            self.status = TASK_STATUS_FINISHED
            
            -- Pár másodperc múlva visszatérés a sétához
            setTimer(function()
                if isElement(ped) and not isPedDead(ped) then
                    local tm = PedManager.getTaskManager(ped)
                    if tm then
                        tm:setTask(CTaskComplexWander:new(), TASK_PRIMARY_DEFAULT)
                    end
                end
            end, 2500, 1)
        end
    end
    
    return self.status
end

-- ==============================================================================
-- 2. CTaskComplexExtinguishFire (Tűzoltás poroltóval - GTA SA TaskComplexExtinguishFires)
-- ==============================================================================
CTaskComplexExtinguishFire = setmetatable({}, { __index = CTaskComplex })
CTaskComplexExtinguishFire.__index = CTaskComplexExtinguishFire

function CTaskComplexExtinguishFire:new(targetVehicle, fireX, fireY, fireZ)
    local instance = CTaskComplex.new(self, TASK_COMPLEX_EXTINGUISH_FIRE)
    instance.targetVehicle = targetVehicle
    instance.fireX = fireX
    instance.fireY = fireY
    instance.fireZ = fireZ
    instance.state = "APPROACH" -- APPROACH, SPRAY, DONE
    instance.sprayStartTime = 0
    instance.sprayDuration = 6000
    return instance
end

function CTaskComplexExtinguishFire:makeAbortable(ped)
    if isElement(ped) then
        setPedControlState(ped, "forwards", false)
        setPedControlState(ped, "sprint", false)
        setPedControlState(ped, "aim_weapon", false)
        setPedControlState(ped, "fire", false)
        setPedAnalogControlState(ped, "forwards", 0)
    end
    self.status = TASK_STATUS_ABORTED
    return true
end

function CTaskComplexExtinguishFire:process(ped)
    if not isElement(ped) or isPedDead(ped) then
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    local tx, ty, tz = self.fireX, self.fireY, self.fireZ
    if isElement(self.targetVehicle) then
        tx, ty, tz = getElementPosition(self.targetVehicle)
    end
    
    if not tx then
        self:makeAbortable(ped)
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    local now = getTickCount()
    local px, py, pz = getElementPosition(ped)
    local dist = MathUtils.getDistance2D(px, py, tx, ty)
    
    if self.state == "APPROACH" then
        if dist > 6.5 then
            local targetRot = MathUtils.findRotation(px, py, tx, ty)
            setPedCameraRotation(ped, targetRot)
            setElementRotation(ped, 0, 0, targetRot, "default", true)
            setPedControlState(ped, "forwards", true)
            setPedControlState(ped, "sprint", true)
            setPedAnalogControlState(ped, "forwards", 1.0)
            setPedControlState(ped, "aim_weapon", false)
            setPedControlState(ped, "fire", false)
        else
            setPedControlState(ped, "forwards", false)
            setPedControlState(ped, "sprint", false)
            setPedAnalogControlState(ped, "forwards", 0)
            
            self.state = "SPRAY"
            self.sprayStartTime = now
        end
        
    elseif self.state == "SPRAY" then
        local targetRot = MathUtils.findRotation(px, py, tx, ty)
        setPedCameraRotation(ped, targetRot)
        setElementRotation(ped, 0, 0, targetRot, "default", true)
        
        -- Célzás és permetezés a poroltóval (weapon 42)
        setPedAimTarget(ped, tx, ty, tz + 0.5)
        setPedControlState(ped, "aim_weapon", true)
        setPedControlState(ped, "fire", true)
        
        if now - self.sprayStartTime >= self.sprayDuration then
            setPedControlState(ped, "aim_weapon", false)
            setPedControlState(ped, "fire", false)
            
            -- Tűzoltás befejezése
            if isElement(self.targetVehicle) then
                triggerServerEvent("sp_npc:extinguishVehicle", resourceRoot, self.targetVehicle)
            end
            
            self.state = "DONE"
            self.status = TASK_STATUS_FINISHED
        end
    end
    
    return self.status
end

-- ==============================================================================
-- 3. CTaskComplexPoliceArrest (Rendőri letartóztatás 1 csillagnál - GTA SA Arrest)
-- ==============================================================================
CTaskComplexPoliceArrest = setmetatable({}, { __index = CTaskComplex })
CTaskComplexPoliceArrest.__index = CTaskComplexPoliceArrest

function CTaskComplexPoliceArrest:new(suspect)
    local instance = CTaskComplex.new(self, TASK_COMPLEX_POLICE_ARREST)
    instance.suspect = suspect
    instance.arrestStartTime = 0
    return instance
end

function CTaskComplexPoliceArrest:makeAbortable(ped)
    if isElement(ped) then
        setPedControlState(ped, "forwards", false)
        setPedControlState(ped, "sprint", false)
        setPedControlState(ped, "aim_weapon", false)
        setPedControlState(ped, "fire", false)
    end
    self.status = TASK_STATUS_ABORTED
    return true
end

function CTaskComplexPoliceArrest:process(ped)
    if not isElement(ped) or isPedDead(ped) or not isElement(self.suspect) or isPedDead(self.suspect) then
        self:makeAbortable(ped)
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    local px, py, pz = getElementPosition(ped)
    local sx, sy, sz = getElementPosition(self.suspect)
    local dist = MathUtils.getDistance2D(px, py, sx, sy)
    
    local targetRot = MathUtils.findRotation(px, py, sx, sy)
    setPedCameraRotation(ped, targetRot)
    setElementRotation(ped, 0, 0, targetRot, "default", true)
    
    -- Ha a gyanúsított fegyvert ránt vagy lő, azonnali tűzharcra váltás
    local isArmed = getPedControlState(self.suspect, "fire") or getPedControlState(self.suspect, "aim_weapon")
    if isArmed or (getPlayerWantedLevel() and getPlayerWantedLevel() >= 2) then
        local taskMgr = PedManager.getTaskManager(ped)
        if taskMgr then
            taskMgr:setTask(CTaskComplexKillPedOnFoot:new(self.suspect), TASK_PRIMARY_EVENT_RESPONSE_NONTEMP)
        end
        return TASK_STATUS_FINISHED
    end
    
    if dist > 2.0 then
        -- Közeledés a gyanúsítotthoz fegyvert fogva
        setPedControlState(ped, "forwards", true)
        setPedControlState(ped, "sprint", true)
        setPedAnalogControlState(ped, "forwards", 1.0)
        setPedAimTarget(ped, sx, sy, sz + 0.6)
        setPedControlState(ped, "aim_weapon", true)
    else
        -- 2 méteren belül: Letartóztatás (Busted)
        setPedControlState(ped, "forwards", false)
        setPedControlState(ped, "sprint", false)
        setPedAnalogControlState(ped, "forwards", 0)
        setPedControlState(ped, "aim_weapon", true)
        
        if self.suspect == localPlayer then
            triggerEvent("sp_npc:onPlayerBusted", localPlayer, ped)
            triggerServerEvent("sp_npc:playerBusted", resourceRoot)
        end
        
        self.status = TASK_STATUS_FINISHED
        
        setTimer(function()
            if isElement(ped) and not isPedDead(ped) then
                setPedControlState(ped, "aim_weapon", false)
                local tm = PedManager.getTaskManager(ped)
                if tm then
                    tm:setTask(CTaskComplexWander:new(), TASK_PRIMARY_DEFAULT)
                end
            end
        end, 4000, 1)
    end
    
    return self.status
end
