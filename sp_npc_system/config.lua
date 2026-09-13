-- ==============================================================================
-- GTA San Andreas Single Player NPC System for MTA:SA
-- Configuration File
-- ==============================================================================

Config = {}

-- Debug beállítások
Config.Debug = false               -- Részletes konzolüzenetek és látómező/útvonal kirajzolás
Config.ShowPedBlips = false        -- Térképi ikonok megjelenítése a teszteléshez

-- Populáció és spawn határok
Config.MaxPedsPerPlayer = 18       -- Egy játékos körül egyszerre aktív maximális NPC szám
Config.MaxGlobalPeds = 120         -- Szerverszintű globális NPC plafon
Config.SpawnRadiusMin = 28.0       -- Minimális távolság a játékostól spawnoláskor (hogy ne közvetlenül előtte teremjen)
Config.SpawnRadiusMax = 65.0       -- Maximális távolság a játékostól spawnoláskor
Config.DespawnRadius = 85.0        -- Ezen távolság felett a ped törlődik (cull)
Config.BehindPlayerDespawnDist = 55.0 -- Ha a játékos mögött van és távolodik, gyorsabb despawn

-- Időzítések (ms)
Config.SpawnCheckInterval = 3000   -- Milyen gyakran ellenőrizze a kliens a populációt és spawnoljon újakat
Config.AITickInterval = 50         -- AI döntési és vezérlési ciklus (20 FPS AI tick sima mozgáshoz)
Config.ScannerInterval = 250       -- Látómező, lövés- és veszélykereső ciklus
Config.DespawnCheckInterval = 4000 -- Távolság- és culling-ellenőrzés gyakorisága

-- AI Viselkedési beállítások
Config.EnableFleeing = true        -- Menekülés engedélyezése sérüléskor / lövéskor
Config.EnableCombat = true         -- Harc engedélyezése (bandák, agresszív polgárok, rendőrök)
Config.EnableHandsUpOnAim = true   -- Célzáskor feltett kéz normál civileknél
Config.EnableCarDiveAway = true    -- Autó közeledésekor elugrás az útból
Config.EnablePedChat = true        -- Két sétáló ped véletlenszerű megállása beszélgetni
Config.EnableLookAt = true         -- Fej fordítása az elhaladó játékos / autók felé (GTA SA IK LookAt)
Config.EnableHornReactions = true  -- Dudálásra való reakció (ökölrázás / középső ujj vagy menekülés)
Config.EnableGangWars = true       -- Ellenséges bandák közötti harc találkozáskor (Acquaintance HATE)
Config.EnableCopPursuit = true     -- Rendőrök üldözik a körözött vagy fegyverrel támadó játékost
Config.EnablePedBump = true        -- Játékossal való ütközéskor meglökés / düh reakció

-- Fegyvereloszlás
Config.GangWeaponChance = 65       -- Bandatagok fegyvertartási esélye (%)
Config.CopWeaponChance = 100       -- Rendőrök fegyvertartási esélye (%)
Config.CivilianWeaponChance = 8    -- Agresszív civilek fegyvertartási esélye (%)

-- Sebzési szorzók (ped.dat alapján skálázva)
Config.DamageMultiplier = 1.0
