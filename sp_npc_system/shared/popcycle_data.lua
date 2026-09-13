-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Popcycle & Skin / Vehicle Distribution Tables
-- ==============================================================================

PopcycleData = {}

-- Gyalogos Skin csoportok városonként (SA = Los Santos, SF = San Fierro, LV = Las Venturas)
PopcycleData.SkinGroups = {
    WORKERS = {
        SA = {35, 27, 153, 50, 71},
        SF = {27, 153, 71, 234, 35},
        LV = {27, 153, 35, 71, 182}
    },
    BUSINESS = {
        SA = {20, 17, 18, 12, 20, 12, 40, 46, 40, 46, 59, 59, 18, 91, 99, 17, 18},
        SF = {185, 227, 187, 17, 18, 219, 185, 40, 46, 40, 46, 186, 186, 18, 91, 99, 17, 18},
        LV = {20, 17, 18, 12, 20, 12, 40, 46, 40, 46, 59, 59, 91, 99, 17, 18}
    },
    CLUBBERS = {
        SA = {12, 20, 201, 224, 203, 204, 205, 206, 40, 46, 59, 91, 99, 200},
        SF = {72, 73, 142, 229, 203, 18, 188, 233, 219, 185, 40, 46, 186, 216, 240, 200},
        LV = {201, 224, 203, 204, 205, 206, 12, 20, 40, 46, 59, 91, 99, 200}
    },
    FARMERS = {207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217},
    BEACHFOLK = {138, 18, 45, 45, 92, 18, 92, 220, 221},
    PARKFOLK = {
        SA = {90, 90, 26, 51, 52, 138, 45},
        SF = {72, 73, 90, 90, 26, 51, 52},
        LV = {90, 90, 26, 51, 52, 92, 138}
    },
    CASUAL_RICH = {
        SA = {9, 12, 14, 20, 38, 40, 43, 46, 54, 59, 50, 55, 91, 99, 94, 88, 17, 18},
        SF = {215, 219, 221, 185, 38, 40, 43, 46, 224, 186, 228, 169, 216, 240, 240, 231, 17, 18},
        LV = {9, 12, 14, 20, 38, 40, 43, 46, 54, 59, 50, 55, 91, 99, 94, 88, 17, 18, 222}
    },
    CASUAL_AVERAGE = {
        SA = {19, 13, 201, 226, 224, 204, 203, 41, 48, 225, 227, 205, 225, 244, 245},
        SF = {222, 13, 201, 229, 226, 170, 41, 48, 225, 233, 188, 225},
        LV = {13, 201, 224, 204, 203, 41, 48, 225, 227, 205, 225}
    },
    CASUAL_POOR = {
        SA = {13, 201, 223, 19, 224, 41, 48, 225, 226, 203, 204, 246, 224, 204, 203, 227, 227, 205, 225, 247, 223},
        SF = {248, 13, 201, 170, 226, 225, 229, 226, 170, 233, 236, 232, 72, 73, 134, 77, 135, 137, 136, 239, 249},
        LV = {250, 224, 13, 201, 41, 48, 225, 226, 203, 204, 246, 224, 204, 203, 227, 227, 205, 225, 251, 252}
    },
    PROSTITUTES = {
        SA = {240, 241, 242, 243, 63, 64, 152},
        SF = {244, 245, 246, 63, 64},
        LV = {247, 248, 249, 152}
    },
    CRIMINALS = {
        SA = {21, 22, 23},
        SF = {24, 25, 26},
        LV = {27, 28, 29}
    },
    GOLFERS = {50, 51},
    SERVANTS = {222, 52, 53, 35},
    AIRCREW = {228, 229, 227},
    ENTERTAINERS = {
        SA = {19},
        SF = {19},
        LV = {230, 231, 232}
    },
    OUT_OF_TOWN_FACTORY_WORKERS = {27, 153, 50},
    DESERT_FOLK = {238, 239, 240, 241, 242, 243, 244, 233, 234, 235, 236, 133, 237},
    AIRCREW_RUNWAY = {228, 229, 227},
    BALLAS = {102, 103, 104},
    FAMILIES = {105, 106, 107},
    LSV = {108, 109, 110},
    SFR = {114, 115, 116},
    DNB = {121, 122, 123},
    VMAFF = {124, 125, 126, 127},
    TRIADS = {117, 118, 120},
    VLA = {173, 174, 175},
    DEALERS = {28, 29, 30, 254},
    COPS = {280, 281, 282, 283, 284, 285, 288}
}

-- Jármű csoportok az NPC sofőrök és bandák számára
PopcycleData.VehicleGroups = {
    WORKERS = {401, 420, 438, 426, 428, 507, 526, 533, 551, 579, 477, 405},
    BUSINESS = {402, 409, 438, 437, 589},
    CLUBBERS = {468, 478, 508, 531, 586, 463, 460},
    FARMERS = {420, 438, 424, 462, 466, 467, 500, 471, 510, 448, 436, 547, 550, 554, 579, 400, 404, 489, 505, 479, 442, 458, 422, 482, 530, 418, 572, 582, 413, 440, 583},
    BEACHFOLK = {420, 438, 424, 462, 466, 467, 500, 471, 510, 448, 436, 547, 550, 554, 579, 400, 404, 489, 505, 479, 442, 458, 422, 482, 530, 418, 572, 582, 413, 440, 583},
    PARKFOLK = {409, 402, 438, 437, 551, 533, 587, 405, 580, 529, 550, 566, 540, 421, 466, 462, 464, 471, 510, 448, 424, 436, 547, 550, 554, 579},
    CASUAL_RICH = {420, 438, 426, 507, 526, 533, 551, 579, 477, 405},
    CASUAL_AVERAGE = {420, 438, 426, 507, 526, 533, 551, 579, 477, 405},
    CASUAL_POOR = {424, 400, 401, 410, 412},
    PROSTITUTES = {424, 412, 479},
    CRIMINALS = {457, 410, 436},
    GOLFERS = {409, 442, 422},
    BALLAS = {466, 412, 566},
    FAMILIES = {467, 424, 474, 567},
    LSV = {475, 439, 440, 536},
    SFR = {518, 410, 549},
    DNB = {405, 445, 533},
    VMAFF = {560, 561, 562},
    TRIADS = {474, 580, 466},
    VLA = {405, 536, 567},
    COPS = {596, 597, 598, 599}
}

-- Kiválaszt egy random skint egy adott zónatípus és város alapján
function PopcycleData.getRandomSkin(zoneType, city, isNight)
    city = city or "SA"
    local groupKey = "CASUAL_AVERAGE"
    
    if zoneType == "BUSINESS" then
        groupKey = "BUSINESS"
    elseif zoneType == "BEACH" then
        groupKey = "BEACHFOLK"
    elseif zoneType == "PARK" then
        groupKey = "PARKFOLK"
    elseif zoneType == "RESIDENTIAL_RICH" then
        groupKey = "CASUAL_RICH"
    elseif zoneType == "RESIDENTIAL_POOR" then
        groupKey = isNight and (math.random(1, 100) <= 30 and "PROSTITUTES" or "CASUAL_POOR") or "CASUAL_POOR"
    elseif zoneType == "GANGLAND" then
        local roll = math.random(1, 100)
        if roll <= 45 then
            -- Bandatag kiválasztása a várostól függően
            if city == "SF" then
                groupKey = (math.random(1, 2) == 1) and "SFR" or "TRIADS"
            elseif city == "LV" then
                groupKey = "VMAFF"
            else
                groupKey = (math.random(1, 2) == 1) and "FAMILIES" or "BALLAS"
            end
        elseif roll <= 60 then
            groupKey = "DEALERS"
        else
            groupKey = "CASUAL_POOR"
        end
    elseif zoneType == "INDUSTRY" or zoneType == "OUT_OF_TOWN_FACTORY" then
        groupKey = "WORKERS"
    elseif zoneType == "DESERT" or zoneType == "COUNTRYSIDE" then
        groupKey = (zoneType == "DESERT") and "DESERT_FOLK" or "FARMERS"
    elseif zoneType == "GOLF_CLUB" then
        groupKey = "GOLFERS"
    elseif zoneType == "AIRPORT" or zoneType == "AIRPORT_RUNWAY" then
        groupKey = "AIRCREW"
    elseif zoneType == "SHOPPING_BUSY LAS VEGAS" then
        groupKey = isNight and "CLUBBERS" or "CASUAL_RICH"
    end
    
    local pool = PopcycleData.SkinGroups[groupKey]
    if not pool then pool = PopcycleData.SkinGroups.CASUAL_AVERAGE end
    
    -- Ha városonként bontott a lista
    if pool.SA or pool.SF or pool.LV then
        pool = pool[city] or pool.SA
    end
    
    if type(pool) == "table" and #pool > 0 then
        return pool[math.random(1, #pool)], groupKey
    end
    
    return 19, "CASUAL_AVERAGE"
end
