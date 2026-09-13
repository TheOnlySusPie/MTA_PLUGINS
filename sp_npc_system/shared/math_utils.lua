-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Math & Geometry Utilities
-- ==============================================================================

MathUtils = {}

function MathUtils.getDistance3D(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function MathUtils.getDistance2D(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Visszaadja a GTA SA-ban használt Ped rotációt (fokban) a kiindulóponttól a célpont felé
function MathUtils.findRotation(x1, y1, x2, y2)
    local rot = -math.deg(math.atan2(x2 - x1, y2 - y1))
    if rot < 0 then
        rot = rot + 360
    end
    return rot
end

-- Normalizálja a szöget 0 és 360 fok közé
function MathUtils.normalizeAngle(angle)
    local newAngle = angle % 360
    if newAngle < 0 then
        newAngle = newAngle + 360
    end
    return newAngle
end

-- Kiszámítja a legkisebb szögeltérést két szög között (-180 és +180 fok között)
function MathUtils.getAngleDifference(targetAngle, currentAngle)
    local diff = (targetAngle - currentAngle + 180) % 360 - 180
    return diff < -180 and diff + 360 or diff
end

-- Kiszámol egy pontot egy adott pozíciótól adott irányban és távolságban
function MathUtils.getPointInFront(x, y, angle, distance)
    local rad = math.rad(-angle)
    local fx = x + (distance * math.sin(rad))
    local fy = y + (distance * math.cos(rad))
    return fx, fy
end

function MathUtils.clamp(val, lower, upper)
    if lower > upper then lower, upper = upper, lower end
    return math.max(lower, math.min(upper, val))
end

function MathUtils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Ellenőrzi, hogy a pont a megfigyelő látómezejében van-e (alapértelmezett FOV: 70 fok)
function MathUtils.isPointInFieldOfView(viewerX, viewerY, viewerRot, targetX, targetY, maxFov)
    maxFov = maxFov or 70
    local targetAngle = MathUtils.findRotation(viewerX, viewerY, targetX, targetY)
    local diff = math.abs(MathUtils.getAngleDifference(targetAngle, viewerRot))
    return diff <= (maxFov / 2)
end
