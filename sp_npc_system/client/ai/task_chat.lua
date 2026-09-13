-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- CTaskComplexChat (Two Pedestrians Greeting & Talking on the Street)
-- ==============================================================================

CTaskComplexChat = setmetatable({}, { __index = CTaskComplex })
CTaskComplexChat.__index = CTaskComplexChat

function CTaskComplexChat:new(partnerPed, isLeader)
    local instance = CTaskComplex.new(self, TASK_COMPLEX_CHAT)
    instance.partnerPed = partnerPed
    instance.isLeader = (isLeader == true)
    instance.duration = math.random(5000, 9000)
    instance.startTime = getTickCount()
    instance.initiated = false
    return instance
end

function CTaskComplexChat:makeAbortable(ped)
    if isElement(ped) then
        setPedAnimation(ped, false)
        setPedControlState(ped, "forwards", false)
    end
    self.status = TASK_STATUS_ABORTED
    return true
end

function CTaskComplexChat:process(ped)
    if not isElement(ped) or not isElement(self.partnerPed) then
        self:makeAbortable(ped)
        self.status = TASK_STATUS_FINISHED
        return self.status
    end
    
    local now = getTickCount()
    
    if not self.initiated then
        self.initiated = true
        self.startTime = now
        
        -- Megállás és szembefordulás a partnerrel
        setPedControlState(ped, "forwards", false)
        setPedControlState(ped, "walk", false)
        setPedControlState(ped, "sprint", false)
        
        local px, py = getElementPosition(ped)
        local tx, ty = getElementPosition(self.partnerPed)
        local rot = MathUtils.findRotation(px, py, tx, ty)
        setPedCameraRotation(ped, rot)
        setElementRotation(ped, 0, 0, rot, "default", true)
        
        -- Animáció: a beszélő kézmozdulatokat tesz, a másik figyel
        if self.isLeader then
            setPedAnimation(ped, "ped", "idle_chat", -1, true, false, false, false)
        else
            setPedAnimation(ped, "ped", "wait_state", -1, true, false, false, false)
        end
    end
    
    if now - self.startTime >= self.duration then
        setPedAnimation(ped, false)
        self.status = TASK_STATUS_FINISHED
    end
    
    return self.status
end
