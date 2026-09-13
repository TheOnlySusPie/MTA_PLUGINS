-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- CTaskComplexKillPedOnFoot (Combat AI: Melee combos & Firearm bursts)
-- ==============================================================================

CTaskComplexKillPedOnFoot = setmetatable({}, { __index = CTaskComplex })
CTaskComplexKillPedOnFoot.__index = CTaskComplexKillPedOnFoot

function CTaskComplexKillPedOnFoot:new(targetEntity)
    local instance = CTaskComplex.new(self, TASK_COMPLEX_KILL_PED_ON_FOOT)
    instance.targetEntity = targetEntity
    instance.lastBurstTime = 0
    instance.burstDuration = math.random(300, 700)
    instance.isFiring = false
    instance.strafeDir = 0
    instance.lastStrafeTime = 0
    return instance
end

function CTaskComplexKillPedOnFoot:makeAbortable(ped)
    if isElement(ped) then
        setPedControlState(ped, "forwards", false)
        setPedControlState(ped, "sprint", false)
        setPedControlState(ped, "fire", false)
        setPedControlState(ped, "aim_weapon", false)
        setPedControlState(ped, "left", false)
        setPedControlState(ped, "right", false)
    end
    self.status = TASK_STATUS_ABORTED
    return true
end

function CTaskComplexKillPedOnFoot:process(ped)
    if not isElement(ped) or not isElement(self.targetEntity) or isPedDead(self.targetEntity) then
        self:makeAbortable(ped)
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    local now = getTickCount()
    local px, py, pz = getElementPosition(ped)
    local tx, ty, tz = getElementPosition(self.targetEntity)
    local dist = MathUtils.getDistance2D(px, py, tx, ty)
    
    -- Ha a célpont túl messze szökött (> 45m), feladja az üldözést
    if dist > 45.0 then
        self:makeAbortable(ped)
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    -- Célpont felé fordulás
    local targetRot = MathUtils.findRotation(px, py, tx, ty)
    setPedCameraRotation(ped, targetRot)
    setElementRotation(ped, 0, 0, targetRot, "default", true)
    
    local weapon = getPedWeapon(ped)
    local isArmedWithGun = (weapon and weapon >= 22 and weapon <= 38)
    
    -- ===================================================
    -- 1. LŐFEGYVERES HARC (Pisztoly, SMG, Shotgun, AK47)
    -- ===================================================
    if isArmedWithGun then
        -- Célzás a célpont mellkasára
        setPedAimTarget(ped, tx, ty, tz + 0.4)
        setPedControlState(ped, "aim_weapon", true)
        
        -- Látómező ellenőrzése (ne lőjön a falba)
        local hasClearShot = CollisionUtils.hasClearLineOfSight(px, py, pz + 0.6, tx, ty, tz + 0.6, ped)
        
        if dist > 26.0 or not hasClearShot then
            -- Közeledés a célponthoz
            setPedControlState(ped, "forwards", true)
            setPedAnalogControlState(ped, "forwards", 1.0)
            setPedControlState(ped, "sprint", true)
            setPedControlState(ped, "fire", false)
        else
            -- Lőtávolságon belül: megáll, tüzel és strafel
            setPedControlState(ped, "forwards", false)
            setPedAnalogControlState(ped, "forwards", 0)
            setPedControlState(ped, "sprint", false)
            
            -- Szakaszos sorozatlövés (Burst Fire szimuláció)
            if self.isFiring then
                if now - self.lastBurstTime >= self.burstDuration then
                    self.isFiring = false
                    self.lastBurstTime = now
                    self.burstDuration = math.random(300, 600) -- Szünet a lövések között
                    setPedControlState(ped, "fire", false)
                else
                    setPedControlState(ped, "fire", true)
                end
            else
                if now - self.lastBurstTime >= self.burstDuration then
                    self.isFiring = true
                    self.lastBurstTime = now
                    self.burstDuration = math.random(400, 900) -- Lövési időtartam
                    setPedControlState(ped, "fire", true)
                else
                    setPedControlState(ped, "fire", false)
                end
            end
            
            -- Enyhe oldalazás (strafe) lövés közben
            if now - self.lastStrafeTime > 1500 then
                self.lastStrafeTime = now
                local roll = math.random(1, 3)
                if roll == 1 then
                    setPedControlState(ped, "left", true)
                    setPedControlState(ped, "right", false)
                elseif roll == 2 then
                    setPedControlState(ped, "left", false)
                    setPedControlState(ped, "right", true)
                else
                    setPedControlState(ped, "left", false)
                    setPedControlState(ped, "right", false)
                end
            end
        end

    -- ===================================================
    -- 2. KÖZELHARC (Ököl, Kés, Ütő, Boxer)
    -- ===================================================
    else
        setPedControlState(ped, "aim_weapon", false)
        setPedControlState(ped, "left", false)
        setPedControlState(ped, "right", false)
        
        if dist > 1.7 then
            -- Rohanjon a célpont felé
            setPedControlState(ped, "forwards", true)
            setPedAnalogControlState(ped, "forwards", 1.0)
            setPedControlState(ped, "sprint", true)
            setPedControlState(ped, "fire", false)
        else
            -- Ütéstávolság: megállás és ütéskombó
            setPedControlState(ped, "forwards", false)
            setPedAnalogControlState(ped, "forwards", 0)
            setPedControlState(ped, "sprint", false)
            setPedControlState(ped, "fire", true)
        end
    end
    
    return self.status
end
