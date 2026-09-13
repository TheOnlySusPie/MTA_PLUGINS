-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Task Base Classes (CTask, CTaskComplex, CTaskSimple)
-- ==============================================================================

-- Task állapot konstansok
TASK_STATUS_RUNNING  = 1
TASK_STATUS_FINISHED = 2
TASK_STATUS_ABORTED  = 3

-- Task Típus konstansok (Megegyeznek a GTA SA eTaskType értékekkel)
TASK_NONE                           = 0
TASK_SIMPLE_STAND_STILL             = 1
TASK_SIMPLE_GO_TO_POINT             = 2
TASK_SIMPLE_FIGHT                   = 3
TASK_SIMPLE_USE_GUN                 = 4
TASK_SIMPLE_DUCK                    = 5
TASK_COMPLEX_WANDER                 = 10
TASK_COMPLEX_SMART_FLEE_ENTITY      = 11
TASK_COMPLEX_KILL_PED_ON_FOOT       = 12
TASK_COMPLEX_CHAT                   = 13
TASK_COMPLEX_DIVE_AWAY              = 14
TASK_COMPLEX_HANDS_UP               = 15
TASK_COMPLEX_COWER                  = 16
TASK_SIMPLE_SHAKE_FIST              = 17
TASK_SIMPLE_LOOK_ABOUT              = 18
TASK_COMPLEX_MEDIC_CPR              = 19
TASK_COMPLEX_EXTINGUISH_FIRE        = 20
TASK_COMPLEX_POLICE_ARREST          = 21

TaskNames = {
    [TASK_NONE]                      = "None",
    [TASK_SIMPLE_STAND_STILL]        = "StandStill",
    [TASK_SIMPLE_GO_TO_POINT]        = "GoToPoint",
    [TASK_SIMPLE_FIGHT]              = "Fight",
    [TASK_SIMPLE_USE_GUN]            = "UseGun",
    [TASK_SIMPLE_DUCK]               = "Duck",
    [TASK_COMPLEX_WANDER]            = "WANDER",
    [TASK_COMPLEX_SMART_FLEE_ENTITY] = "SMART_FLEE",
    [TASK_COMPLEX_KILL_PED_ON_FOOT]  = "COMBAT",
    [TASK_COMPLEX_CHAT]              = "CHAT",
    [TASK_COMPLEX_DIVE_AWAY]         = "DIVE_AWAY",
    [TASK_COMPLEX_HANDS_UP]          = "HANDS_UP",
    [TASK_COMPLEX_COWER]             = "COWER",
    [TASK_SIMPLE_SHAKE_FIST]         = "SHAKE_FIST",
    [TASK_SIMPLE_LOOK_ABOUT]         = "LOOK_ABOUT",
    [TASK_COMPLEX_MEDIC_CPR]         = "MEDIC_CPR",
    [TASK_COMPLEX_EXTINGUISH_FIRE]   = "EXTINGUISH_FIRE",
    [TASK_COMPLEX_POLICE_ARREST]     = "POLICE_ARREST",
}

-- ==============================================================================
-- CTask Alaposztály
-- ==============================================================================
CTask = {}
CTask.__index = CTask

function CTask:new(taskType)
    local instance = setmetatable({}, self)
    instance.taskType = taskType or TASK_NONE
    instance.parent = nil
    instance.subTask = nil
    instance.status = TASK_STATUS_RUNNING
    return instance
end

function CTask:getTaskType()
    return self.taskType
end

function CTask:getSubTask()
    return self.subTask
end

function CTask:setSubTask(subTask)
    self.subTask = subTask
    if subTask then
        subTask.parent = self
    end
end

function CTask:makeAbortable(ped)
    if self.subTask then
        self.subTask:makeAbortable(ped)
    end
    self.status = TASK_STATUS_ABORTED
    return true
end

function CTask:process(ped)
    return self.status
end

-- ==============================================================================
-- CTaskComplex (Összetett feladat, amely részegységekre / subtaskokra bomlik)
-- ==============================================================================
CTaskComplex = setmetatable({}, { __index = CTask })
CTaskComplex.__index = CTaskComplex

function CTaskComplex:new(taskType)
    local instance = CTask.new(self, taskType)
    return setmetatable(instance, self)
end

function CTaskComplex:createFirstSubTask(ped)
    return nil
end

function CTaskComplex:createNextSubTask(ped)
    return nil
end

function CTaskComplex:controlSubTask(ped)
    -- Lehetővé teszi, hogy a complex task közbeszóljon a subtask futásába
end

function CTaskComplex:process(ped)
    if self.status ~= TASK_STATUS_RUNNING then
        return self.status
    end
    
    -- Ha még nincs subtask, létrehozzuk az elsőt
    if not self.subTask then
        self:setSubTask(self:createFirstSubTask(ped))
        if not self.subTask then
            self.status = TASK_STATUS_FINISHED
            return self.status
        end
    end
    
    -- Futtatjuk a complex task felügyeleti logikáját
    self:controlSubTask(ped)
    
    -- Futtatjuk az aktív subtaskot
    local subStatus = self.subTask:process(ped)
    
    if subStatus == TASK_STATUS_FINISHED then
        -- Ha befejeződött, lekérjük a következőt
        self:setSubTask(self:createNextSubTask(ped))
        if not self.subTask then
            self.status = TASK_STATUS_FINISHED
        end
    elseif subStatus == TASK_STATUS_ABORTED then
        self.status = TASK_STATUS_ABORTED
    end
    
    return self.status
end

-- ==============================================================================
-- CTaskSimple (Levélfeladat, közvetlenül vezérli a ped mozgását / állapotát)
-- ==============================================================================
CTaskSimple = setmetatable({}, { __index = CTask })
CTaskSimple.__index = CTaskSimple

function CTaskSimple:new(taskType)
    local instance = CTask.new(self, taskType)
    return setmetatable(instance, self)
end

function CTaskSimple:process(ped)
    return self.status
end
