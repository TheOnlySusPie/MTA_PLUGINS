-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Zones & Area Mapping (16 SP Zone Types)
-- ==============================================================================

ZonesData = {}

-- A 16 hivatalos Single Player spawn zóna típus
ZonesData.Types = {
    "BUSINESS",
    "DESERT",
    "COUNTRYSIDE",
    "RESIDENTIAL_RICH",
    "RESIDENTIAL_AVERAGE",
    "RESIDENTIAL_POOR",
    "GANGLAND",
    "BEACH",
    "PARK",
    "INDUSTRY",
    "SHOPPING_BUSY LAS VEGAS",
    "AIRPORT",
    "GOLF_CLUB",
    "OUT_OF_TOWN_FACTORY",
    "AIRPORT_RUNWAY"
}

-- GTA SA zóna nevek leképezése a zónatípusokra
ZonesData.ZoneToTypeMap = {
    -- Los Santos
    ["Ganton"]                  = "GANGLAND",
    ["Idlewood"]                = "GANGLAND",
    ["East Los Santos"]         = "GANGLAND",
    ["Jefferson"]               = "GANGLAND",
    ["Glen Park"]               = "GANGLAND",
    ["Las Colinas"]             = "GANGLAND",
    ["Los Flores"]              = "GANGLAND",
    ["Willowfield"]             = "RESIDENTIAL_POOR",
    ["Playa del Seville"]       = "RESIDENTIAL_POOR",
    ["Ocean Docks"]             = "INDUSTRY",
    ["Commerce"]                = "BUSINESS",
    ["Downtown"]                = "BUSINESS",
    ["Market"]                  = "BUSINESS",
    ["Marina"]                  = "RESIDENTIAL_AVERAGE",
    ["Rodeo"]                   = "RESIDENTIAL_RICH",
    ["Mulholland"]              = "RESIDENTIAL_RICH",
    ["Vinewood"]                = "RESIDENTIAL_RICH",
    ["Richman"]                 = "RESIDENTIAL_RICH",
    ["Santa Maria Beach"]       = "BEACH",
    ["Verona Beach"]            = "BEACH",
    ["Verdant Bluffs"]          = "PARK",
    ["Los Santos International"]= "AIRPORT",
    ["Garcia"]                  = "RESIDENTIAL_AVERAGE",

    -- San Fierro
    ["Battery Point"]           = "RESIDENTIAL_AVERAGE",
    ["Chinatown"]               = "GANGLAND",
    ["Calton Heights"]          = "RESIDENTIAL_RICH",
    ["City Hall"]               = "BUSINESS",
    ["Downtown San Fierro"]     = "BUSINESS",
    ["Financial"]               = "BUSINESS",
    ["Easter Basin"]            = "INDUSTRY",
    ["Esplanade East"]          = "BUSINESS",
    ["Esplanade North"]         = "BEACH",
    ["Juniper Hill"]            = "RESIDENTIAL_AVERAGE",
    ["Juniper Hollow"]          = "RESIDENTIAL_AVERAGE",
    ["King's"]                  = "BUSINESS",
    ["Ocean Flats"]             = "RESIDENTIAL_AVERAGE",
    ["Palisades"]               = "RESIDENTIAL_RICH",
    ["Paradiso"]                = "RESIDENTIAL_RICH",
    ["Queens"]                  = "RESIDENTIAL_AVERAGE",
    ["Santa Flora"]             = "RESIDENTIAL_AVERAGE",
    ["Avispa Country Club"]     = "GOLF_CLUB",
    ["Easter Bay Airport"]      = "AIRPORT",

    -- Las Venturas
    ["Blackfield"]              = "RESIDENTIAL_AVERAGE",
    ["Caligula's Casino"]       = "SHOPPING_BUSY LAS VEGAS",
    ["The Strip"]               = "SHOPPING_BUSY LAS VEGAS",
    ["Old Venturas Strip"]      = "SHOPPING_BUSY LAS VEGAS",
    ["Redsands East"]           = "RESIDENTIAL_AVERAGE",
    ["Redsands West"]           = "RESIDENTIAL_AVERAGE",
    ["Roca Escalante"]          = "BUSINESS",
    ["Rockshore East"]          = "RESIDENTIAL_POOR",
    ["Rockshore West"]          = "RESIDENTIAL_AVERAGE",
    ["The Camel's Toe"]         = "SHOPPING_BUSY LAS VEGAS",
    ["The Four Dragons Casino"] = "SHOPPING_BUSY LAS VEGAS",
    ["The High Roller"]         = "SHOPPING_BUSY LAS VEGAS",
    ["The Pink Swan"]           = "SHOPPING_BUSY LAS VEGAS",
    ["The Visage"]              = "SHOPPING_BUSY LAS VEGAS",
    ["Come-A-Lot"]              = "SHOPPING_BUSY LAS VEGAS",
    ["Pirates in Men's Pants"]  = "SHOPPING_BUSY LAS VEGAS",
    ["Las Venturas Airport"]    = "AIRPORT",
    ["Spinybed"]                = "OUT_OF_TOWN_FACTORY",
    ["Sobell Rail Yards"]       = "INDUSTRY",
    ["Prickle Pine"]            = "RESIDENTIAL_RICH",
    ["Whitewood Estates"]       = "RESIDENTIAL_AVERAGE",
    ["Yellow Bell Golf Club"]   = "GOLF_CLUB",

    -- Vidék / Sivatag
    ["Bone County"]             = "DESERT",
    ["Red County"]              = "COUNTRYSIDE",
    ["Flint County"]            = "COUNTRYSIDE",
    ["Tierra Robada"]           = "DESERT",
    ["Whetstone"]               = "COUNTRYSIDE",
    ["Angel Pine"]              = "COUNTRYSIDE",
    ["Palomino Creek"]          = "COUNTRYSIDE",
    ["Montgomery"]              = "COUNTRYSIDE",
    ["Dillimore"]               = "COUNTRYSIDE",
    ["Blueberry"]               = "COUNTRYSIDE",
    ["Fort Carson"]             = "DESERT",
    ["El Quebrados"]            = "DESERT",
    ["Las Payasadas"]           = "DESERT",
    ["Bayside"]                 = "RESIDENTIAL_AVERAGE",
    ["Aldea Malvada"]           = "DESERT"
}

-- Lekéri egy adott 3D koordináta zónatípusát és városkódját (SA, SF, LV)
function ZonesData.getZoneInfo(x, y, z)
    local zoneName = getZoneName(x, y, z, false)
    local cityName = getZoneName(x, y, z, true)
    
    local cityCode = "SA"
    if cityName == "San Fierro" then
        cityCode = "SF"
    elseif cityName == "Las Venturas" then
        cityCode = "LV"
    end
    
    local zoneType = ZonesData.ZoneToTypeMap[zoneName]
    if not zoneType then
        if cityName == "Bone County" or cityName == "Tierra Robada" then
            zoneType = "DESERT"
        elseif cityName == "Red County" or cityName == "Flint County" or cityName == "Whetstone" then
            zoneType = "COUNTRYSIDE"
        else
            zoneType = "RESIDENTIAL_AVERAGE"
        end
    end
    
    return zoneType, cityCode, zoneName
end
