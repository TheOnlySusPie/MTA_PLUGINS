-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Collision & Raycast Utilities (Obstacle Avoidance & Ground Detection)
-- ==============================================================================

CollisionUtils = {}

-- Megkeresi a pontos talajmagasságot (Z) a megadott (X, Y) koordinátán
function CollisionUtils.getGroundZ(x, y, startZ)
    startZ = startZ or 100.0
    -- Fentről lefelé lövünk egy raycastet (épületek, objektumok, talaj figyelembevételével)
    local hit, hitX, hitY, hitZ = processLineOfSight(
        x, y, startZ + 15.0,
        x, y, startZ - 50.0,
        true,  -- checkBuildings
        true,  -- checkVehicles
        false, -- checkPeds
        true,  -- checkObjects
        true,  -- checkDummies
        false, -- seeThroughStuff
        false, -- ignoreSomeObjectsForCamera
        false  -- shootThroughStuff
    )
    
    if hit then
        return hitZ
    end
    
    -- Fallback: MTA beépített getGroundPosition
    local gz = getGroundPosition(x, y, startZ)
    if gz and gz ~= 0 then
        return gz
    end
    
    return startZ
end

-- Ellenőrzi, hogy van-e akadály (fal, autó, másik ped) a ped előtt egy adott távolságban és szögeltéréssel
function CollisionUtils.isObstacleInDirection(ped, distance, angleOffset)
    if not isElement(ped) then return true end
    
    distance = distance or 1.8
    angleOffset = angleOffset or 0
    
    local px, py, pz = getElementPosition(ped)
    local prot = getPedCameraRotation(ped) or getElementRotation(ped)
    local checkAngle = MathUtils.normalizeAngle(prot + angleOffset)
    
    local targetX, targetY = MathUtils.getPointInFront(px, py, checkAngle, distance)
    
    -- Sugárindítás a ped mellmagasságából (~ +0.5m)
    local hit, hitX, hitY, hitZ, hitElement = processLineOfSight(
        px, py, pz + 0.5,
        targetX, targetY, pz + 0.5,
        true,  -- checkBuildings
        true,  -- checkVehicles
        true,  -- checkPeds
        true,  -- checkObjects
        true,  -- checkDummies
        false,
        false,
        false,
        ped    -- ignoreElement (maga a ped)
    )
    
    if hit then
        -- Ha saját magát vagy elhanyagolható elemet talált
        if hitElement == ped then
            return false
        end
        return true, hitX, hitY, hitZ, hitElement
    end
    
    return false
end

-- Megkeresi a legtisztább menekülési / kikerülési irányt, ha a ped előtt akadály van
function CollisionUtils.findClearAngle(ped)
    if not isElement(ped) then return 0 end
    
    local currentRot = getPedCameraRotation(ped) or getElementRotation(ped)
    
    -- Először megnézzük a kisebb kitéréseket (+45°, -45°, +90°, -90°, +135°, -135°, 180°)
    local anglesToTest = { 45, -45, 90, -90, 135, -135, 180 }
    
    for _, offset in ipairs(anglesToTest) do
        local blocked = CollisionUtils.isObstacleInDirection(ped, 2.2, offset)
        if not blocked then
            return MathUtils.normalizeAngle(currentRot + offset)
        end
    end
    
    -- Ha minden irány blokkolva van, forduljon meg teljesen
    return MathUtils.normalizeAngle(currentRot + 180)
end

-- Látómező és takarásmentesség ellenőrzése két entitás között
function CollisionUtils.hasClearLineOfSight(x1, y1, z1, x2, y2, z2, ignoreElement)
    local hit = processLineOfSight(
        x1, y1, z1,
        x2, y2, z2,
        true,  -- checkBuildings
        true,  -- checkVehicles
        false, -- checkPeds
        true,  -- checkObjects
        true,  -- checkDummies
        false,
        false,
        false,
        ignoreElement
    )
    return not hit
end
