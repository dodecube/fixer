item_to_upgrade = {
    ["Progressive Processing Level"] = "processLvl",
    ["Progressive Processing Speed"] = "processSpeed",
    ["Progressive Download Speed"] = "downloadSpd",
    ["Progressive Cursor Drift"] = "coordDrift",
    ["Progressive Cursor Speed"] = "coordMovementSpeed",
    ["Progressive Ping Speed"] = "coordPingSpeed",
    ["Progressive Ping Cooldown"] = "coordCooldown",
    ["Progressive Coordinate Speed"] = "coordRadarSpeed",
    ["Progressive Radar History"] = "radarHist",
    ["Progressive Radar Speed"] = "radar",
    ["Progressive Breaker Time"] = "compTime",
    ["Progressive Detector Quality"] = "detecQual",
    ["Progressive Detector Strength"] = "scanner",
    ["Progressive Detector Frequency"] = "scannerFr",
    ["Progressive Ping Strength"] = "triangleProb",
    -- Unused
    ["Progressive Filter Size"] = "downloadFiltSize",
    ["Progressive Server Stability"] = "serverStability",
    ["Progressive Transformer Stability"] = "transformer"
}

auto_map = {
    ["Plastic Scrap Recipe"] =              { hint = HintType.Thought, run = function() UnlockRecipe("Plastic Scrap Recipe") end, replay = true },
    ["Metal Scrap Recipe"] =                { hint = HintType.Thought, run = function() UnlockRecipe("Metal Scrap Recipe") end, replay = true },
    ["Electronic Scrap Recipe"] =           { hint = HintType.Thought, run = function() UnlockRecipe("Electronic Scrap Recipe") end, replay = true },
    ["Glass Scrap Recipe"] =                { hint = HintType.Thought, run = function() UnlockRecipe("Glass Scrap Recipe") end, replay = true },
    ["Rubber Scrap Recipe"] =               { hint = HintType.Thought, run = function() UnlockRecipe("Rubber Scrap Recipe") end, replay = true },
    ["Paper Scrap Recipe"] =                { hint = HintType.Thought, run = function() UnlockRecipe("Paper Scrap Recipe") end, replay = true },
    ["Wood Scrap Recipe"] =                 { hint = HintType.Thought, run = function() UnlockRecipe("Wood Scrap Recipe") end, replay = true },
    ["Rubble Recipe"] =                     { hint = HintType.Thought, run = function() UnlockRecipe("Rubble Recipe") end, replay = true },

    ["Day"] =                               { hint = HintType.Thought, run = function() have_days = have_days + 1 end, replay = true },

    ["Lifecrystal Signal"] = {
        hint = HintType.Thought,
        run = function()
            local SaveGameObject = GetSaveSlot()
            if SaveGameObject ~= nil then
                SaveGameObject.forceObjects[#SaveGameObject.forceObjects + 1] = FName("lifecrystal")
            end
        end
    },
    ["Bonus Points"] = {
        hint = HintType.Info,
        run = function()
            local Gamemode = GetGameMode()
            if Gamemode:IsValid() then
                Gamemode:AddPoints(options.BonusPointsAmount)
            end
        end
    },
    ["Positive Reputation"] = {
        hint = HintType.Info,
        run = function()
            local SaveSlot = GetSaveSlot()
            if SaveSlot then
                SaveSlot.arirReputation = SaveSlot.arirReputation + options.AriralReputationAmount
            end
        end
    },

    ["Random Fuse Blowout"] = { hint = HintType.Warning, run = function() SetPendingFuseBlowouts(GetPendingFuseBlowouts() + 1) end },

    ["Ragdoll Trap"] = { hint = HintType.Error, run = function() MakePlayerRagdoll() end },
    ["Breaker Trap"] = {
        hint = HintType.Error,
        run = function()
            local Gamemode = GetGameMode()
            if Gamemode:IsValid() then
                Gamemode.eventer.event_solar:runTrigger(Gamemode, 0)
            end
        end
    },
    ["Dead Flashlight Trap"] = {
        hint = HintType.Error,
        run = function()
            local SaveGameObject = GetSaveSlot()
            if SaveGameObject ~= nil then
                SaveGameObject.battery = 0
            end
        end
    },
    ["Debug TP Trap"] = {
        hint = HintType.Error,
        run = function()
            local Gamemode = GetGameMode()
            if Gamemode:IsValid() then
                Gamemode:debugtp()
            end
        end
    },
    ["Flat Tire Trap"] = {
        hint = HintType.Error,
        run = function()
            local Gamemode = GetGameMode()
            if Gamemode:IsValid() then
                Gamemode.car:damageWheel(0, 100, Gamemode.car.frontWheel_R)
            end
        end
    },
    ["Drunk Trap"] = {
        hint = HintType.Error,
        run = function()
            local beer = SpawnSomething("/Game/objects/prop_snack_beer.prop_snack_beer_C")
            local Pawn = GetPawn()
            if beer:IsValid() and Pawn:IsValid() then
                beer:openBottle()
                beer:eat(Pawn, true)
                beer:eat(Pawn, true)
                beer:eat(Pawn, true)
                beer:eat(Pawn, true)
                beer:K2_DestroyActor()
            end
        end
    },
    ["Points Fine Trap"] = {
        hint = HintType.Error,
        run = function()
            local Gamemode = GetGameMode()
            if Gamemode:IsValid() then
                Gamemode:AddPoints(-100)
            end
        end
    },
    ["Negative Reputation Trap"] = {
        hint = HintType.Error,
        run = function()
            local SaveSlot = GetSaveSlot()
            if SaveSlot then
                SaveSlot.arirReputation = SaveSlot.arirReputation - options.AriralReputationAmount
            end
        end
    },
    ["Black Fog Trap"] = {
        hint = HintType.Error,
        run = function()
            local Gamemode = GetGameMode()
            if Gamemode:IsValid() then
                Gamemode:spawnBlackFog()
            end
        end
    },
    ["Alien Cutout Trap"] = {
        hint = HintType.Error,
        run = function()
            local doors = FindAllOf("door_C")
            for i=1,3 do
                local j = math.random(1, #doors)
                doors[j].alienated = true
            end
        end
    },

    ["Victory"] = { hint = HintType.Info, run = function() end }
}

for k,v in pairs(item_to_upgrade) do
    auto_map[k] = { hint = HintType.Info, run = function() Upgrade(v) end }
end

for k,_ in pairs(entrance_to_door) do
    auto_map[k] = { hint = HintType.Thought, run = function() UnlockDoor(k) end, replay = true }
end

for k,_ in pairs(item_to_breaker) do
    auto_map[k] = { hint = HintType.Thought, run = function() UnlockBreaker(k) end, replay = true }
end

complex_item_map = {
    ["Progressive Sleeping Bag"] = function()
        local i = 0
        for j=1,GetRecievedItems() do
            if GetAPItemNameFromId(item_list[j].item) == "Progressive Sleeping Bag" then
                i = i + 1
            end
        end

        if i == 0 then
            GiveItem("sleepingbag")
        elseif i == 1 then
            GiveItem("sleepingbag_br")
        elseif i == 2 then
            GiveItem("sleepingbag_st")
        else
            AddHint("You collected too many sleeping bags!", HintType.Error)
        end
    end,
    ["Progressive Camera"] = function()
        local i = 0
        for j=1,GetRecievedItems() do
            if GetAPItemNameFromId(item_list[j].item) == "Progressive Camera" then
                i = i + 1
            end
        end

        if i <= 2 then
            GiveItem("cam_h_" .. i)
        else
            AddHint("You collected too many cameras!", HintType.Error)
        end
    end,
    ["Bunker Keycard"] = function()
        GiveItem("keycard", function(item) item.Open = "ALPHA_HIDEOUT" end)
    end,
    ["Kerfur-Omega Complete Manual"] = function()
        local Pawn = GetPawn()
        local blueprint = SpawnSomething("/Game/objects/prop_blueprint_kerfurOmega.prop_blueprint_kerfurOmega_C")
        if Pawn:IsValid() and blueprint:IsValid() then
            blueprint.Key = FName("APItem")
            Pawn:putObjectInventory2(blueprint, false, {})
        end
    end,
    ["Scuba Gear"] = function()
        GiveItem("scuba")
        GiveItem("scuba_t")
    end,
    ["Kerfur"] = function()
        SpawnSomething("/Game/objects/p_kerfus.p_kerfus_C")
    end,
    ["Blue Kerfur"] = function()
        SpawnSomething("/Game/objects/p_kerfus.p_kerfus_C")
    end,
    ["Red Kerfur"] = function()
        SpawnSomething("/Game/objects/p_kerfus_r.p_kerfus_r_C")
    end,
    ["Pink Kerfur"] = function()
        SpawnSomething("/Game/objects/p_kerfus_p.p_kerfus_p_C")
    end,
    ["Skull"] = function()
        -- The skull in the prop data is not a valid skull for the ritual
        local Pawn = GetPawn()
        local blueprint = SpawnSomething("/Game/objects/prop_sskull.prop_sskull_C")
        if Pawn:IsValid() and blueprint:IsValid() then
            blueprint.Key = FName("APItem")
            Pawn:putObjectInventory2(blueprint, false, {})
        end
    end
}

item_map = {}
inverse_item_map = {}
function FillItemMap()
    item_map = {}
    inverse_item_map = {}
    local datatable = StaticFindObject("/Game/main/datatables/list_props.list_props")
    if datatable:IsValid() then
        print("Filling item map with " .. #datatable .. " items")
        local total = 0
        datatable:ForEachRow(function(k, v)
            local name = v.displayName_8_FE83ADBF40AA162942FCE589F5806DD2:ToString()

            -- Special cases
            if k == "lig" then name = "" end
            if k == "ligo" then name = "" end
            if k == "radio_n" then name = "" end
            if k == "Blueprint_1" then name = "Radioactive Capsule Blueprint" end
            if k == "animalhead_0" then name = "Deer Skull" end

            if name ~= "" then
                item_map[k] = name
                if inverse_item_map[string.lower(name)] == nil then
                    inverse_item_map[string.lower(name)] = k
                end
                total = total + 1
            end
        end)
        -- To make both Shrimps Pack and Shrimp Pack valid
        inverse_item_map["shrimp pack"] = "shrimp"
        total = total + 1
        for k,name in pairs(locationKeys) do
            if inverse_item_map[string.lower(name)] == nil then
                inverse_item_map[string.lower(name)] = k
                total = total + 1
            end
        end
        print("Filtered down to " .. total .. " items")
    end
end
