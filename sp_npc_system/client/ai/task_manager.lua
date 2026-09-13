-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- CTaskManager (Hierarchical Priority Task Manager)
-- ==============================================================================

-- Elsődleges Task Slotok (Prioritási sorrend: 0 a legmagasabb, 4 a legalacsonyabb)
TASK_PRIMARY_PHYSICAL_RESPONSE       = 0 -- Esés, gázolási felborulás, ragdoll
TASK_PRIMARY_EVENT_RESPONSE_TEMP     = 1 -- Megrettenés, elugrás, fedezék, feltett kéz
TASK_PRIMARY_EVENT_RESPONSE_NONTEMP  = 2 -- Menekülés (SmartFlee), harc (KillPedOnFoot)
TASK_PRIMARY_PRIMARY                 = 3 -- Szkriptelt parancsok
TASK_PRIMARY_DEFAULT                 = 4 -- Alapértelmezett séta (Wander), bandázás
TASK_PRIMARY_MAX                     = 5

-- Másodlagos Task Slotok
TASK_SECONDARY_ATTACK                = 0
TASK_SECONDARY_DUCK                  = 1
TASK_SECONDARY_PARTIAL_ANIM          = 2
TASK_SECONDARY_MAX                   = 3

CTaskManager = {}
CTaskManager.__index = CTaskManager

function CTaskManager:new(ped)
    local instance = setmetatable({}, self)
    instance.ped = ped
    instance.primaryTasks = {}
    instance.secondaryTasks = {}
    
    for i = 0, TASK_PRIMARY_MAX - 1 do
        instance.primaryTasks[i] = nil
    end
    for i = 0, TASK_SECONDARY_MAX - 1 do
        instance.secondaryTasks[i] = nil
    end
    
    return instance
end

-- Beállít egy elsődleges feladatot az adott prioritási slotba
function CTaskManager:setTask(task, priorityIndex)
    if not priorityIndex or priorityIndex < 0 or priorityIndex >= TASK_PRIMARY_MAX then
        priorityIndex = TASK_PRIMARY_DEFAULT
    end
    
    -- Ha volt előző feladat ebben a slotban, megszakítjuk
    local oldTask = self.primaryTasks[priorityIndex]
    if oldTask and oldTask ~= task then
        oldTask:makeAbortable(self.ped)
    end
    
    self.primaryTasks[priorityIndex] = task
end

-- Beállít egy másodlagos feladatot
function CTaskManager:setSecondaryTask(task, secondaryIndex)
    if not secondaryIndex or secondaryIndex < 0 or secondaryIndex >= TASK_SECONDARY_MAX then
        return
    end
    
    local oldTask = self.secondaryTasks[secondaryIndex]
    if oldTask and oldTask ~= task then
        oldTask:makeAbortable(self.ped)
    end
    
    self.secondaryTasks[secondaryIndex] = task
end

-- Lekéri az éppen legmagasabb prioritású aktív elsődleges feladatot
function CTaskManager:getActiveTask()
    for i = 0, TASK_PRIMARY_MAX - 1 do
        local task = self.primaryTasks[i]
        if task and task.status == TASK_STATUS_RUNNING then
            return task, i
        end
    end
    return nil, -1
end

-- Megkeresi, hogy van-e adott típusú feladat bármelyik slotban
function CTaskManager:hasTaskType(taskType)
    for i = 0, TASK_PRIMARY_MAX - 1 do
        local task = self.primaryTasks[i]
        if task and task:getTaskType() == taskType and task.status == TASK_STATUS_RUNNING then
            return true
        end
    end
    return false
end

-- Megszakítja az összes feladatot és kitakarítja a ped vezérlőit
function CTaskManager:clearTasks()
    for i = 0, TASK_PRIMARY_MAX - 1 do
        if self.primaryTasks[i] then
            self.primaryTasks[i]:makeAbortable(self.ped)
            self.primaryTasks[i] = nil
        end
    end
    for i = 0, TASK_SECONDARY_MAX - 1 do
        if self.secondaryTasks[i] then
            self.secondaryTasks[i]:makeAbortable(self.ped)
            self.secondaryTasks[i] = nil
        end
    end
    
    if isElement(self.ped) then
        setPedControlState(self.ped, "forwards", false)
        setPedControlState(self.ped, "sprint", false)
        setPedControlState(self.ped, "walk", false)
        setPedControlState(self.ped, "fire", false)
        setPedControlState(self.ped, "aim_weapon", false)
    end
end

-- Fő feldolgozó ciklus (az AI tick hívja meg)
function CTaskManager:process()
    if not isElement(self.ped) or isPedDead(self.ped) then
        return
    end
    
    local activeTask, activeIndex = self:getActiveTask()
    if activeTask then
        local status = activeTask:process(self.ped)
        if status == TASK_STATUS_FINISHED or status == TASK_STATUS_ABORTED then
            self.primaryTasks[activeIndex] = nil
            
            -- Ha a feladat befejeződött, a ped vezérlőit alaphelyzetbe hozzuk a következő task előtt
            setPedControlState(self.ped, "forwards", false)
            setPedControlState(self.ped, "sprint", false)
            setPedControlState(self.ped, "fire", false)
        end
    end
    
    -- Másodlagos feladatok futtatása
    for i = 0, TASK_SECONDARY_MAX - 1 do
        local secTask = self.secondaryTasks[i]
        if secTask then
            local status = secTask:process(self.ped)
            if status == TASK_STATUS_FINISHED or status == TASK_STATUS_ABORTED then
                self.secondaryTasks[i] = nil
            end
        end
    end
end
