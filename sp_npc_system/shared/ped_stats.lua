-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Pedestrian Stats Table (100% Matching ped.dat / GTA SA Engine)
-- ==============================================================================

PedStats = {}

-- Decision Maker Konstansok
PedStats.DECISION_MAKER_GROUP_MEMBER = 0
PedStats.DECISION_MAKER_COP          = 1
PedStats.DECISION_MAKER_RAND_NORM    = 2
PedStats.DECISION_MAKER_RAND_TOUGH   = 3
PedStats.DECISION_MAKER_RAND_WEAK    = 4
PedStats.DECISION_MAKER_FIREMAN      = 5

-- Statisztikák táblázata (A-K oszlopok az eredeti ped.dat és a leírófájl alapján)
-- Mezők:
-- fleeDistance: Menekülési távolság (float)
-- headingChangeRate: Fordulási sebesség fokban (float)
-- fear: Félelem (0-100) -> 100 = mindentől megijed
-- temper: Indulati hajlam (0-100) -> 100 = agresszív, azonnal támad
-- lawfulness: Törvénytisztelet (0-100) -> 100 = mintapolgár, rendőrt hív/tiszteli a törvényt
-- sexiness: Vonzóerő (0-100)
-- attackStrength: Támadási sebzés szorzó (float)
-- defendWeakness: Sérülékenységi szorzó (float)
-- shootingRate: Harci / lövési hajlandóság (0-100)
-- defaultDecisionMaker: Viselkedési döntéshozó típus (0-5)

PedStats.Types = {
    ["STAT_PLAYER"]        = { fleeDistance = 0.0,  headingChangeRate = 9.0, fear = 50,  temper = 50,  lawfulness = 50,  sexiness = 50,  attackStrength = 3.0, defendWeakness = 0.4, shootingRate = 40, defaultDecisionMaker = 2 },
    ["STAT_COP"]           = { fleeDistance = 20.0, headingChangeRate = 7.5, fear = 10,  temper = 30,  lawfulness = 100, sexiness = 50,  attackStrength = 1.0, defendWeakness = 1.0, shootingRate = 40, defaultDecisionMaker = 1 },
    ["STAT_MEDIC"]         = { fleeDistance = 20.0, headingChangeRate = 7.5, fear = 70,  temper = 30,  lawfulness = 60,  sexiness = 40,  attackStrength = 0.8, defendWeakness = 1.4, shootingRate = 40, defaultDecisionMaker = 2 },
    ["STAT_FIREMAN"]       = { fleeDistance = 20.0, headingChangeRate = 7.5, fear = 10,  temper = 20,  lawfulness = 60,  sexiness = 80,  attackStrength = 1.2, defendWeakness = 0.8, shootingRate = 40, defaultDecisionMaker = 5 },
    ["STAT_GANG1"]         = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 20,  temper = 65,  lawfulness = 10,  sexiness = 40,  attackStrength = 1.0, defendWeakness = 1.0, shootingRate = 45, defaultDecisionMaker = 3 },
    ["STAT_GANG2"]         = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 20,  temper = 65,  lawfulness = 10,  sexiness = 40,  attackStrength = 1.0, defendWeakness = 1.0, shootingRate = 45, defaultDecisionMaker = 3 },
    ["STAT_GANG3"]         = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 20,  temper = 65,  lawfulness = 10,  sexiness = 40,  attackStrength = 1.0, defendWeakness = 1.0, shootingRate = 45, defaultDecisionMaker = 3 },
    ["STAT_GANG4"]         = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 20,  temper = 65,  lawfulness = 10,  sexiness = 40,  attackStrength = 1.0, defendWeakness = 1.0, shootingRate = 45, defaultDecisionMaker = 3 },
    ["STAT_GANG5"]         = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 20,  temper = 65,  lawfulness = 10,  sexiness = 40,  attackStrength = 1.0, defendWeakness = 1.0, shootingRate = 45, defaultDecisionMaker = 3 },
    ["STAT_GANG6"]         = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 20,  temper = 65,  lawfulness = 10,  sexiness = 40,  attackStrength = 1.0, defendWeakness = 1.0, shootingRate = 45, defaultDecisionMaker = 3 },
    ["STAT_GANG7"]         = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 20,  temper = 65,  lawfulness = 10,  sexiness = 40,  attackStrength = 1.0, defendWeakness = 1.0, shootingRate = 45, defaultDecisionMaker = 3 },
    ["STAT_GANG8"]         = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 20,  temper = 65,  lawfulness = 10,  sexiness = 40,  attackStrength = 1.0, defendWeakness = 1.0, shootingRate = 45, defaultDecisionMaker = 3 },
    ["STAT_GANG9"]         = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 20,  temper = 65,  lawfulness = 10,  sexiness = 40,  attackStrength = 1.0, defendWeakness = 1.0, shootingRate = 45, defaultDecisionMaker = 3 },
    ["STAT_GANG10"]        = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 20,  temper = 65,  lawfulness = 10,  sexiness = 40,  attackStrength = 1.0, defendWeakness = 1.0, shootingRate = 45, defaultDecisionMaker = 3 },
    ["STAT_STREET_GUY"]    = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 45,  temper = 30,  lawfulness = 30,  sexiness = 60,  attackStrength = 1.0, defendWeakness = 1.0, shootingRate = 40, defaultDecisionMaker = 2 },
    ["STAT_SUIT_GUY"]      = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 35,  temper = 60,  lawfulness = 60,  sexiness = 30,  attackStrength = 0.8, defendWeakness = 1.2, shootingRate = 40, defaultDecisionMaker = 2 },
    ["STAT_SENSIBLE_GUY"]  = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 65,  temper = 30,  lawfulness = 70,  sexiness = 20,  attackStrength = 0.7, defendWeakness = 1.1, shootingRate = 40, defaultDecisionMaker = 4 },
    ["STAT_GEEK_GUY"]      = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 56,  temper = 10,  lawfulness = 40,  sexiness = 5,   attackStrength = 0.5, defendWeakness = 1.7, shootingRate = 40, defaultDecisionMaker = 4 },
    ["STAT_OLD_GUY"]       = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 40,  temper = 10,  lawfulness = 40,  sexiness = 5,   attackStrength = 0.4, defendWeakness = 2.5, shootingRate = 40, defaultDecisionMaker = 2 },
    ["STAT_TOUGH_GUY"]     = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 30,  temper = 70,  lawfulness = 50,  sexiness = 60,  attackStrength = 1.1, defendWeakness = 1.5, shootingRate = 55, defaultDecisionMaker = 3 },
    ["STAT_STREET_GIRL"]   = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 45,  temper = 30,  lawfulness = 30,  sexiness = 60,  attackStrength = 0.9, defendWeakness = 1.0, shootingRate = 40, defaultDecisionMaker = 2 },
    ["STAT_SUIT_GIRL"]     = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 30,  temper = 60,  lawfulness = 60,  sexiness = 30,  attackStrength = 0.6, defendWeakness = 1.6, shootingRate = 40, defaultDecisionMaker = 2 },
    ["STAT_SENSIBLE_GIRL"] = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 65,  temper = 30,  lawfulness = 70,  sexiness = 20,  attackStrength = 0.5, defendWeakness = 1.1, shootingRate = 40, defaultDecisionMaker = 4 },
    ["STAT_GEEK_GIRL"]     = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 80,  temper = 10,  lawfulness = 40,  sexiness = 5,   attackStrength = 0.4, defendWeakness = 1.9, shootingRate = 40, defaultDecisionMaker = 4 },
    ["STAT_OLD_GIRL"]      = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 80,  temper = 10,  lawfulness = 40,  sexiness = 5,   attackStrength = 0.3, defendWeakness = 3.0, shootingRate = 40, defaultDecisionMaker = 2 },
    ["STAT_TOUGH_GIRL"]    = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 30,  temper = 70,  lawfulness = 50,  sexiness = 60,  attackStrength = 1.1, defendWeakness = 1.5, shootingRate = 50, defaultDecisionMaker = 3 },
    ["STAT_TRAMP_MALE"]    = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 60,  temper = 50,  lawfulness = 20,  sexiness = 10,  attackStrength = 0.9, defendWeakness = 1.6, shootingRate = 35, defaultDecisionMaker = 3 },
    ["STAT_TRAMP_FEMALE"]  = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 30,  temper = 30,  lawfulness = 20,  sexiness = 10,  attackStrength = 0.9, defendWeakness = 1.6, shootingRate = 40, defaultDecisionMaker = 3 },
    ["STAT_TOURIST"]       = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 100, temper = 20,  lawfulness = 70,  sexiness = 30,  attackStrength = 0.8, defendWeakness = 1.8, shootingRate = 40, defaultDecisionMaker = 2 },
    ["STAT_PROSTITUTE"]    = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 40,  temper = 20,  lawfulness = 40,  sexiness = 100, attackStrength = 0.7, defendWeakness = 1.0, shootingRate = 40, defaultDecisionMaker = 3 },
    ["STAT_CRIMINAL"]      = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 30,  temper = 55,  lawfulness = 10,  sexiness = 60,  attackStrength = 1.2, defendWeakness = 1.3, shootingRate = 60, defaultDecisionMaker = 3 },
    ["STAT_BUSKER"]        = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 49,  temper = 20,  lawfulness = 40,  sexiness = 90,  attackStrength = 1.0, defendWeakness = 1.0, shootingRate = 40, defaultDecisionMaker = 3 },
    ["STAT_TAXIDRIVER"]    = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 16,  temper = 80,  lawfulness = 30,  sexiness = 30,  attackStrength = 0.8, defendWeakness = 1.5, shootingRate = 40, defaultDecisionMaker = 3 },
    ["STAT_PSYCHO"]        = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 0,   temper = 100, lawfulness = 0,   sexiness = 50,  attackStrength = 1.0, defendWeakness = 1.0, shootingRate = 40, defaultDecisionMaker = 3 },
    ["STAT_STEWARD"]       = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 40,  temper = 30,  lawfulness = 70,  sexiness = 20,  attackStrength = 0.7, defendWeakness = 1.1, shootingRate = 40, defaultDecisionMaker = 4 },
    ["STAT_SPORTSFAN"]     = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 40,  temper = 50,  lawfulness = 70,  sexiness = 20,  attackStrength = 0.7, defendWeakness = 1.1, shootingRate = 40, defaultDecisionMaker = 3 },
    ["STAT_SHOPPER"]       = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 30,  temper = 75,  lawfulness = 50,  sexiness = 40,  attackStrength = 1.5, defendWeakness = 1.5, shootingRate = 40, defaultDecisionMaker = 4 },
    ["STAT_OLDSHOPPER"]    = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 45,  temper = 65,  lawfulness = 70,  sexiness = 20,  attackStrength = 1.0, defendWeakness = 2.5, shootingRate = 40, defaultDecisionMaker = 4 },
    ["STAT_BEACH_GUY"]     = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 52,  temper = 60,  lawfulness = 60,  sexiness = 30,  attackStrength = 0.8, defendWeakness = 1.2, shootingRate = 40, defaultDecisionMaker = 2 },
    ["STAT_BEACH_GIRL"]    = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 59,  temper = 30,  lawfulness = 30,  sexiness = 60,  attackStrength = 0.9, defendWeakness = 1.0, shootingRate = 40, defaultDecisionMaker = 2 },
    ["STAT_SKATER"]        = { fleeDistance = 20.0, headingChangeRate = 6.0, fear = 40,  temper = 40,  lawfulness = 60,  sexiness = 80,  attackStrength = 0.7, defendWeakness = 1.0, shootingRate = 40, defaultDecisionMaker = 4 },
    ["STAT_STD_MISSION"]   = { fleeDistance = 20.0, headingChangeRate = 15.0,fear = 50,  temper = 50,  lawfulness = 50,  sexiness = 50,  attackStrength = 1.0, defendWeakness = 1.0, shootingRate = 40, defaultDecisionMaker = 3 },
    ["STAT_COWARD"]        = { fleeDistance = 17.0, headingChangeRate = 7.5, fear = 65,  temper = 30,  lawfulness = 70,  sexiness = 20,  attackStrength = 0.7, defendWeakness = 1.1, shootingRate = 40, defaultDecisionMaker = 4 }
}

-- Skin ID -> Stat típus hozzárendelések
PedStats.SkinToStatMap = {
    -- Rendőrök
    [280] = "STAT_COP", [281] = "STAT_COP", [282] = "STAT_COP", [283] = "STAT_COP", [284] = "STAT_COP", [285] = "STAT_COP", [288] = "STAT_COP",
    -- Mentős / Tűzoltó
    [274] = "STAT_MEDIC", [275] = "STAT_MEDIC", [276] = "STAT_MEDIC",
    [277] = "STAT_FIREMAN", [278] = "STAT_FIREMAN", [279] = "STAT_FIREMAN",
    -- Bandatagok (Ballas, Families, Vagos, Rifa, DNB, Mafia, Triads, Aztecas)
    [102] = "STAT_GANG1", [103] = "STAT_GANG1", [104] = "STAT_GANG1",
    [105] = "STAT_GANG2", [106] = "STAT_GANG2", [107] = "STAT_GANG2",
    [108] = "STAT_GANG3", [109] = "STAT_GANG3", [110] = "STAT_GANG3",
    [114] = "STAT_GANG4", [115] = "STAT_GANG4", [116] = "STAT_GANG4",
    [121] = "STAT_GANG5", [122] = "STAT_GANG5", [123] = "STAT_GANG5",
    [124] = "STAT_GANG6", [125] = "STAT_GANG6", [126] = "STAT_GANG6",
    [117] = "STAT_GANG7", [118] = "STAT_GANG7", [120] = "STAT_GANG7",
    [173] = "STAT_GANG8", [174] = "STAT_GANG8", [175] = "STAT_GANG8",
    -- Drogdílerek
    [28] = "STAT_CRIMINAL", [29] = "STAT_CRIMINAL", [30] = "STAT_CRIMINAL", [254] = "STAT_CRIMINAL",
    -- Prostituáltak
    [63] = "STAT_PROSTITUTE", [64] = "STAT_PROSTITUTE", [152] = "STAT_PROSTITUTE", [240] = "STAT_PROSTITUTE",
    [241] = "STAT_PROSTITUTE", [242] = "STAT_PROSTITUTE", [243] = "STAT_PROSTITUTE", [244] = "STAT_PROSTITUTE",
    -- Üzletemberek / Öltönyösök
    [17] = "STAT_SUIT_GUY", [18] = "STAT_SUIT_GUY", [20] = "STAT_SUIT_GUY", [228] = "STAT_SUIT_GUY",
    -- Csövesek / Homeless
    [78] = "STAT_TRAMP_MALE", [79] = "STAT_TRAMP_MALE", [134] = "STAT_TRAMP_MALE", [137] = "STAT_TRAMP_MALE",
    [77] = "STAT_TRAMP_FEMALE", [135] = "STAT_TRAMP_FEMALE",
    -- Tengerpart / Fürdőzők
    [97] = "STAT_BEACH_GUY", [138] = "STAT_BEACH_GUY", [45] = "STAT_BEACH_GIRL", [92] = "STAT_BEACH_GIRL"
}

-- Visszaadja egy ped statisztikáit a skin ID alapján (vagy alapértelmezettet, ha nincs explicit leképezve)
function PedStats.getStatsForSkin(skinId)
    local statName = PedStats.SkinToStatMap[skinId]
    if not statName then
        -- Ha nincs egyedi, a skin neme vagy általános kategóriája alapján választ
        statName = "STAT_STREET_GUY"
    end
    return PedStats.Types[statName] or PedStats.Types["STAT_STREET_GUY"]
end

-- Visszaadja az autentikus GTA SA sétastílust (Walking Style) a skin ID alapján
function PedStats.getWalkStyleForSkin(skinId)
    -- Prostituáltak és szexi nők
    if skinId == 63 or skinId == 64 or skinId == 152 or (skinId >= 240 and skinId <= 249) then
        return 132 -- MOVE_PROSTITUTE
    -- Idős nők
    elseif skinId == 56 or skinId == 77 or skinId == 88 or skinId == 89 or skinId == 90 or skinId == 130 or skinId == 131 or skinId == 134 or skinId == 135 then
        return 133 -- MOVE_OLDWOMAN
    -- Idős férfiak
    elseif skinId == 49 or skinId == 50 or skinId == 51 or skinId == 52 or skinId == 53 or skinId == 54 or skinId == 70 or skinId == 78 or skinId == 79 or skinId == 137 or skinId == 142 or skinId == 147 then
        return 122 -- MOVE_OLDMAN
    -- Bandatagok (Ballas, Grove, Vagos, Aztecas, Rifa, DNB, Triad)
    elseif (skinId >= 102 and skinId <= 110) or (skinId >= 114 and skinId <= 127) or (skinId >= 173 and skinId <= 175) then
        return 120 -- MOVE_GANG1
    -- Kövér emberek
    elseif skinId == 6 or skinId == 7 or skinId == 8 or skinId == 14 or skinId == 15 or skinId == 16 or skinId == 201 or skinId == 202 or skinId == 203 then
        return 123 -- MOVE_FATMAN
    -- Üzletemberek / Öltönyösök
    elseif skinId == 17 or skinId == 18 or skinId == 20 or skinId == 228 then
        return 118 -- MOVE_MAN
    -- Általános női skinek
    elseif (skinId >= 9 and skinId <= 13) or skinId == 31 or skinId == 40 or skinId == 41 or skinId == 55 or skinId == 69 or skinId == 75 or skinId == 76 or skinId == 91 or skinId == 92 or skinId == 93 or skinId == 138 or skinId == 140 or skinId == 145 or skinId == 148 or skinId == 150 or skinId == 151 or skinId == 157 or skinId == 169 or skinId == 172 or skinId == 178 or skinId == 190 or skinId == 191 or skinId == 192 or skinId == 193 or skinId == 195 or skinId == 198 or skinId == 214 or skinId == 216 or skinId == 224 or skinId == 225 or skinId == 226 or skinId == 231 or skinId == 232 or skinId == 233 or skinId == 237 or skinId == 238 then
        return 128 -- MOVE_WOMAN
    end
    -- Alapértelmezett férfi séta
    return 118 -- MOVE_MAN
end

-- Visszaadja a banda nevét a skin ID alapján (GTA SA Ped Type / Gangs)
function PedStats.getPedGang(skinId)
    if skinId >= 102 and skinId <= 104 then
        return "BALLAS"
    elseif skinId >= 105 and skinId <= 107 then
        return "GROVE"
    elseif skinId >= 108 and skinId <= 110 then
        return "VAGOS"
    elseif skinId >= 114 and skinId <= 116 then
        return "AZTECAS"
    elseif skinId >= 117 and skinId <= 120 then
        return "TRIAD"
    elseif skinId >= 121 and skinId <= 123 then
        return "DA_NANG"
    elseif skinId >= 124 and skinId <= 126 then
        return "MAFIA"
    elseif skinId >= 173 and skinId <= 175 then
        return "RIFA"
    elseif (skinId >= 280 and skinId <= 285) or skinId == 288 then
        return "COP"
    end
    return nil
end

-- Visszaadja, hogy két banda ellenséges viszonyban van-e egymással (Acquaintance HATE)
function PedStats.areGangsEnemies(gangA, gangB)
    if not gangA or not gangB or gangA == gangB then return false end
    
    -- Grove Street ellenségei
    if gangA == "GROVE" and (gangB == "BALLAS" or gangB == "VAGOS") then return true end
    if (gangA == "BALLAS" or gangA == "VAGOS") and gangB == "GROVE" then return true end
    
    -- Ballas vs Vagos
    if gangA == "BALLAS" and gangB == "VAGOS" then return true end
    if gangA == "VAGOS" and gangB == "BALLAS" then return true end
    
    -- Aztecas vs Vagos & Ballas
    if gangA == "AZTECAS" and (gangB == "VAGOS" or gangB == "BALLAS") then return true end
    if (gangA == "VAGOS" or gangA == "BALLAS") and gangB == "AZTECAS" then return true end
    
    -- San Fierro & Las Venturas bandaháborúk
    if gangA == "TRIAD" and (gangB == "DA_NANG" or gangB == "MAFIA") then return true end
    if (gangA == "DA_NANG" or gangA == "MAFIA") and gangB == "TRIAD" then return true end
    
    return false
end

