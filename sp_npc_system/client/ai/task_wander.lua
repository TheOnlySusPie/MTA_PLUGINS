-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- CTaskComplexWander (100% Single Player GTA SA Pedestrian Navigation)
-- ==============================================================================

CTaskComplexWander = setmetatable({}, { __index = CTaskComplex })
CTaskComplexWander.__index = CTaskComplexWander

function CTaskComplexWander:new(wanderType)
    local instance = CTaskComplex.new(self, TASK_COMPLEX_WANDER)
    instance.wanderType = wanderType or "STANDARD"
    instance.state = "SEEK_NODE"               -- SEEK_NODE, FOLLOW_PATH, PAUSED, TURNING_OBSTACLE, CROSSING_ROAD
    instance.currentNode = nil
    instance.targetNode = nil
    instance.previousNodeID = nil
    instance.timer = getTickCount()
    instance.stateDuration = 0
    instance.turnSpeed = 7.5                   -- Élethű kanyarodási sebesség
    -- Személyes sétasebesség (analóg bemenet 0.40 - 0.47 között: természetes, nyugodt léptek)
    instance.walkSpeed = math.random(41, 47) / 100
    -- Járda szélességi eltolás (-0.35m és +0.35m között a TakeWidthIntoAccountForWandering alapján): hogy a járda közepén maradjanak
    instance.lateralOffset = math.random(-35, 35) / 100
    instance.targetRotation = nil
    instance.lastBlockedCheck = 0
    return instance
end

function CTaskComplexWander:makeAbortable(ped)
    if isElement(ped) then
        setPedControlState(ped, "forwards", false)
        setPedAnalogControlState(ped, "forwards", 0)
        setPedControlState(ped, "sprint", false)
        setPedControlState(ped, "walk", false)
        setPedAnimation(ped, false)
    end
    self.status = TASK_STATUS_ABORTED
    return true
end

function CTaskComplexWander:process(ped)
    if not isElement(ped) or isPedDead(ped) then
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    local now = getTickCount()
    local px, py, pz = getElementPosition(ped)
    local _, _, currentRot = getElementRotation(ped)
    
    -- ==========================================================================
    -- 1. ÚTVONAL KERESÉSE (Ha nincs aktív célpont)
    -- ==========================================================================
    if not self.targetNode or self.state == "SEEK_NODE" then
        local closest = PathManager.findClosestNode(px, py, pz, 55.0)
        if closest then
            self.currentNode = closest
            local nextN = PathManager.getRandomNeighbor(closest, self.previousNodeID)
            if nextN then
                self.targetNode = nextN
                self.state = "FOLLOW_PATH"
            else
                self.targetNode = closest
                self.state = "FOLLOW_PATH"
            end
        else
            -- Ha nincs a közelben csomópont (pl. sikátor mélyén), szabad séta előre
            self.state = "FREE_WANDER"
            if not self.targetRotation then
                self.targetRotation = currentRot
            end
            self.stateDuration = math.random(6000, 12000)
            self.timer = now
        end
    end
    
    -- ==========================================================================
    -- 2. ÚTVONAL KÖVETÉSE CSOMÓPONTRÓL CSOMÓPONTRA
    -- ==========================================================================
    if self.state == "FOLLOW_PATH" and self.targetNode then
        -- Kiszámoljuk a célpontot a járda oldalirányú eltolásával (Single Player stílus)
        local baseRot = MathUtils.findRotation(self.currentNode and self.currentNode.x or px, self.currentNode and self.currentNode.y or py, self.targetNode.x, self.targetNode.y)
        local perpAngle = MathUtils.normalizeAngle(baseRot + 90)
        local offX, offY = MathUtils.getPointInFront(0, 0, perpAngle, self.lateralOffset)
        
        local targetX = self.targetNode.x + offX
        local targetY = self.targetNode.y + offY
        local distToNode = MathUtils.getDistance2D(px, py, targetX, targetY)
        
        -- Akadályérzékelés (fal, parkoló autó, egyéb tereptárgy)
        if now - self.lastBlockedCheck > 350 then
            self.lastBlockedCheck = now
            local blocked = CollisionUtils.isObstacleInDirection(ped, 1.8, 0)
            if blocked then
                self.state = "TURNING_OBSTACLE"
                self.targetRotation = CollisionUtils.findClearAngle(ped)
                self.stateDuration = 1800
                self.timer = now
                return self.status
            end
        end
        
        -- Célpont felé fordulás
        local targetRot = MathUtils.findRotation(px, py, targetX, targetY)
        local angleDiff = MathUtils.getAngleDifference(targetRot, currentRot)
        local step = math.min(math.abs(angleDiff), self.turnSpeed) * (angleDiff > 0 and 1 or -1)
        local newRot = MathUtils.normalizeAngle(currentRot + step)
        
        setPedCameraRotation(ped, newRot)
        setElementRotation(ped, 0, 0, newRot, "default", true)
        
        -- TISZTA ANALÓG SÉTA (Nem hívjuk meg a digitális forwards-ot, így pontosan a séta sebességgel megy!)
        setPedControlState(ped, "walk", false)
        setPedControlState(ped, "sprint", false)
        setPedAnalogControlState(ped, "forwards", self.walkSpeed)
        
        -- Ha elérte a csomópontot (< 1.6 méter)
        if distToNode <= 1.6 then
            self.previousNodeID = self.targetNode.id
            local nextNode = PathManager.getRandomNeighbor(self.targetNode, self.previousNodeID)
            
            if nextNode then
                self.currentNode = self.targetNode
                self.targetNode = nextNode
                
                -- Véletlenszerű események a csomópontnál / utcasarkon
                local roll = math.random(1, 100)
                if roll <= 14 then
                    -- Megáll a sarkon / zebránál körbenézni (2.6 - 4.5 másodperc)
                    self.state = "PAUSED"
                    self.stateDuration = math.random(2600, 4500)
                    self.timer = now
                    setPedAnalogControlState(ped, "forwards", 0)
                    setPedControlState(ped, "forwards", false)
                    
                    local animRoll = math.random(1, 100)
                    if animRoll <= 50 then
                        -- CTaskSimpleLookAbout (ped:idle_hbhb)
                        setPedAnimation(ped, "ped", "idle_hbhb", self.stateDuration, false, false, false, false)
                    elseif animRoll <= 80 then
                        -- CTaskSimpleScratchHead (ped:xpressscratch)
                        setPedAnimation(ped, "ped", "xpressscratch", self.stateDuration, false, false, false, false)
                    end
                end
            else
                self.targetNode = nil
                self.state = "SEEK_NODE"
            end
        end

    -- ==========================================================================
    -- 3. AKADÁLYKIKERÜLÉS
    -- ==========================================================================
    elseif self.state == "TURNING_OBSTACLE" then
        local angleDiff = MathUtils.getAngleDifference(self.targetRotation, currentRot)
        local step = math.min(math.abs(angleDiff), self.turnSpeed * 1.6) * (angleDiff > 0 and 1 or -1)
        local newRot = MathUtils.normalizeAngle(currentRot + step)
        setPedCameraRotation(ped, newRot)
        setElementRotation(ped, 0, 0, newRot, "default", true)
        
        setPedAnalogControlState(ped, "forwards", self.walkSpeed)
        
        if now - self.timer >= self.stateDuration or math.abs(angleDiff) <= 4 then
            self.state = "FOLLOW_PATH"
        end

    -- ==========================================================================
    -- 4. MEGÁLLÁS / KÖRBENÉZÉS A CSOMÓPONTON (Zebrák és sarkok)
    -- ==========================================================================
    elseif self.state == "PAUSED" then
        setPedAnalogControlState(ped, "forwards", 0)
        setPedControlState(ped, "forwards", false)
        
        if now - self.timer >= self.stateDuration then
            setPedAnimation(ped, false)
            self.state = "FOLLOW_PATH"
            self.timer = now
        end

    -- ==========================================================================
    -- 5. SZABAD SÉTA (Fallback olyan ritka helyeken, ahol nincs node)
    -- ==========================================================================
    elseif self.state == "FREE_WANDER" then
        setPedControlState(ped, "walk", false)
        setPedControlState(ped, "sprint", false)
        setPedAnalogControlState(ped, "forwards", self.walkSpeed)
        
        local blocked = CollisionUtils.isObstacleInDirection(ped, 2.0, 0)
        if blocked then
            self.targetRotation = CollisionUtils.findClearAngle(ped)
        end
        
        local angleDiff = MathUtils.getAngleDifference(self.targetRotation or currentRot, currentRot)
        local step = math.min(math.abs(angleDiff), self.turnSpeed) * (angleDiff > 0 and 1 or -1)
        local newRot = MathUtils.normalizeAngle(currentRot + step)
        setPedCameraRotation(ped, newRot)
        setElementRotation(ped, 0, 0, newRot, "default", true)
        
        if now - self.timer >= (self.stateDuration or 6000) then
            self.state = "SEEK_NODE"
            self.timer = now
        end
    end
    
    return self.status
end
