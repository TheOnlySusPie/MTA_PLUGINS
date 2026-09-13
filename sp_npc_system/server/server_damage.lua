-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Server Damage & Death Handling (Drops, Defense Multipliers & Cleanup)
-- ==============================================================================

ServerDamage = {}

function ServerDamage.init()
    addEventHandler("onPedDamage", root, ServerDamage.onDamage)
    addEventHandler("onPedWasted", root, ServerDamage.onWasted)
end
addEventHandler("onResourceStart", resourceRoot, ServerDamage.init)

-- Sebzés és védelem szorzók érvényesítése (ped.dat defendWeakness)
function ServerDamage.onDamage(attacker, weapon, bodypart, loss)
    local ped = source
    if not isElement(ped) or not getElementData(ped, "sp_npc:isSPPed") then return end
    
    local skinId = getElementModel(ped)
    local stats = PedStats.getStatsForSkin(skinId)
    
    if stats and stats.defendWeakness then
        -- Ha az NPC védelme eltér az 1.0-tól, korrigáljuk a sebzést
        local multiplier = stats.defendWeakness * Config.DamageMultiplier
        if multiplier ~= 1.0 then
            local adjustedLoss = loss * multiplier
            local currentHp = getElementHealth(ped)
            local diff = adjustedLoss - loss
            if diff > 0 then
                setElementHealth(ped, math.max(0, currentHp - diff))
            end
        end
    end
end

-- Halál esemény: Fegyver és pénz drop, majd eltakarítás
function ServerDamage.onWasted(totalAmmo, killer, killerWeapon, bodypart)
    local ped = source
    if not isElement(ped) or not getElementData(ped, "sp_npc:isSPPed") then return end
    
    local px, py, pz = getElementPosition(ped)
    local weapon = getPedWeapon(ped)
    local ammo = getPedTotalAmmo(ped)
    
    -- 1. Fegyver leejtése halálkor (mint az egyjátékos módban)
    if weapon and weapon > 0 and ammo > 0 then
        -- 2-es típusú pickup = fegyver pickup
        local dropPickup = createPickup(px, py, pz, 2, weapon, 15000, math.min(ammo, 60))
    end
    
    -- 2. Pénz leejtése (Single Playerben a civilek 65% eséllyel dobnak készpénzt)
    if math.random(1, 100) <= 65 then
        local cashAmount = math.random(8, 75)
        -- 1212-es modell = Pénzköteg pickup
        local moneyPickup = createPickup(px + 0.3, py + 0.3, pz, 3, 1212, 15000)
    end
    
    -- 3. Hullaelrejtés és takarítás 18 másodperc múlva
    setTimer(function()
        if isElement(ped) then
            ServerPeds.unregister(ped)
        end
    end, 18000, 1)
end
