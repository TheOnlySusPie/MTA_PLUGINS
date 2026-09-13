-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- PathManager (GTA SA World Path Node Graph Navigation)
-- ==============================================================================

PathManager = {}
PathManager.isLoaded = false

function PathManager.init()
    if vehicleNodes and type(vehicleNodes) == "table" then
        PathManager.isLoaded = true
        local count = 0
        for areaID, nodes in pairs(vehicleNodes) do
            if type(nodes) == "table" then
                count = count + 1
            end
        end
        if Config.Debug then
            outputChatBox(string.format("[SP NPC] Útvonal-hálózat betöltve: %d terület.", count), 100, 255, 100)
        end
    end
end

-- Kiszámolja a koordináta AreaID-jét (0-63 között)
function PathManager.getAreaID(x, y)
    local col = math.floor((x + 3000) / 750)
    local row = math.floor((y + 3000) / 750)
    col = MathUtils.clamp(col, 0, 7)
    row = MathUtils.clamp(row, 0, 7)
    return row * 8 + col
end

-- Lekéri a csomópontot a globális adatbázisból ID alapján
function PathManager.getNodeByID(nodeID)
    if not nodeID or not PathManager.isLoaded then return nil end
    local areaID = math.floor(nodeID / 65536)
    if vehicleNodes[areaID] and vehicleNodes[areaID][nodeID] then
        return vehicleNodes[areaID][nodeID]
    end
    -- Szomszédos szektorok ellenőrzése, ha a kapcsolat átnyúlik a határon
    for a = areaID - 1, areaID + 1 do
        if vehicleNodes[a] and vehicleNodes[a][nodeID] then
            return vehicleNodes[a][nodeID]
        end
    end
    for a = areaID - 8, areaID + 8, 8 do
        if vehicleNodes[a] and vehicleNodes[a][nodeID] then
            return vehicleNodes[a][nodeID]
        end
    end
    return nil
end

-- Megkeresi a pozícióhoz legközelebbi útvonal-csomópontot
function PathManager.findClosestNode(x, y, z, maxDist)
    if not PathManager.isLoaded then return nil end
    maxDist = maxDist or 50.0
    
    local areaID = PathManager.getAreaID(x, y)
    local areaList = { areaID }
    
    -- Határterületek ellenőrzése
    local localX = (x + 3000) % 750
    local localY = (y + 3000) % 750
    if localX < 60 and (areaID % 8) > 0 then table.insert(areaList, areaID - 1) end
    if localX > 690 and (areaID % 8) < 7 then table.insert(areaList, areaID + 1) end
    if localY < 60 and areaID >= 8 then table.insert(areaList, areaID - 8) end
    if localY > 690 and areaID <= 55 then table.insert(areaList, areaID + 8) end
    
    local closestNode = nil
    local shortestDist = maxDist
    
    for _, aID in ipairs(areaList) do
        local nodes = vehicleNodes[aID]
        if nodes then
            for _, node in pairs(nodes) do
                local dist = MathUtils.getDistance2D(x, y, node.x, node.y)
                if dist < shortestDist then
                    -- Ha magasságkülönbség is ésszerű (< 6m)
                    if not z or math.abs(node.z - z) < 6.0 then
                        shortestDist = dist
                        closestNode = node
                    end
                end
            end
        end
    end
    
    return closestNode
end

-- Véletlenszerűen kiválaszt egy szomszédos csomópontot (kizárva azt, amerről jött)
function PathManager.getRandomNeighbor(node, excludeNodeID)
    if not node or not node.neighbours then return nil end
    
    local candidates = {}
    for neighborID, _ in pairs(node.neighbours) do
        if neighborID ~= excludeNodeID then
            table.insert(candidates, neighborID)
        end
    end
    
    -- Ha zsákutca (nincs más kijárat), megengedjük a visszafordulást
    if #candidates == 0 then
        for neighborID, _ in pairs(node.neighbours) do
            table.insert(candidates, neighborID)
        end
    end
    
    if #candidates > 0 then
        local chosenID = candidates[math.random(1, #candidates)]
        return PathManager.getNodeByID(chosenID)
    end
    
    return nil
end
