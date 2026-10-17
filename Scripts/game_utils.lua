local GameplayStatics = nil
function GetGameplayStatics()
    if GameplayStatics == nil or not GameplayStatics:IsValid() then GameplayStatics = UEHelpers:GetGameplayStatics() end
    return GameplayStatics
end

local World = nil
function GetWorld()
    if World == nil or not World:IsValid() then World = UEHelpers:GetWorld() end
    return World
end

local GameMode = nil
function GetGameMode()
    if GameMode == nil or not GameMode:IsValid() then GameMode = GetGameplayStatics():GetGameMode(GetWorld()) end
    if GameMode == nil or not GameMode:IsValid() then GameMode = FindFirstOf("mainGamemode_C") end  -- Safety measure
    return GameMode
end

function GetSaveSlot()
    local GameMode = GetGameMode()
    if GameMode:IsValid() then
        local slot = GameMode.saveSlot
        if slot:IsValid() then
            return slot
        else
            return nil
        end
    else
        return nil
    end
end

local Pawn = nil
function GetPawn()
    if Pawn == nil or not Pawn:IsValid() then
        local FirstPlayerController = UEHelpers:GetPlayerController()
        Pawn = FirstPlayerController.Pawn
    end
    return Pawn
end

local DNC = nil
function GetDNC()
    if DNC == nil or not DNC:IsValid() then
        local dnc = StaticFindObject("/Game/objects/misc/daynightCycle.daynightCycle_C")
        DNC = FindObject(dnc, GetWorld(), "daynightCycle", true)
    end
    return DNC
end

function SpawnSomething(name)
    print("Attempting to spawn " .. name)
    local Class = StaticFindObject(name)
    local Pawn = GetPawn()
    if Class:IsValid() and Pawn:IsValid() then
        local Location = Pawn:K2_GetActorLocation()
        local Rotation = Pawn:K2_GetActorRotation()
        local SpawnedActor = GetWorld():SpawnActor(Class, Location, Rotation)
        return SpawnedActor
    end
    return CreateInvalidObject()
end

function FindWithErrorHint(name)
    local obj = FindFirstOf(name)
    if not obj:IsValid() then AddHint("Failed to find " .. name, HintType.Error) end
    return obj
end

function StaticFindWithErrorHint(name)
    local obj = StaticFindObject(name)
    if not obj:IsValid() then AddHint("Failed to find " .. name, HintType.Error) end
    return obj
end

-- function SendViaDrone()
--     local drone_class = StaticFindObject("/Game/objects/drone.drone_C")
--     local drone = FindObject(drone_class, GetWorld(), "drone", true)
--     local laptop = FindFirstOf("ui_laptop_C")

--     local class = StaticFindObject('/Script/Engine.UserDefinedStruct')
--     --local outer = fucking_class2
--     local outer = StaticFindObject("/Game/main/structs/struct_storeOrder.struct_storeOrder")

--     if class:IsValid() and outer:IsValid() and drone:IsValid() and laptop:IsValid() then
--         local CreatedConsole = StaticConstructObject(class, outer, 0, 0, 0, nil, false, false, nil)
--         outer = StaticFindObject("/Game/main/structs/struct_store.struct_store")
--         local CreatedItem = StaticConstructObject(class, outer, 0, 0, 0, nil, false, false, nil)
--         if CreatedConsole:IsValid() and CreatedItem:IsValid() then
--             local the = "/Game/objects/prop_drive.prop_drive_C"
--             local Class = StaticFindObject(the)
--             --CreatedItem.price_11_BE3AF83E446D1C3BDEA63BA50CFE096C = 2
--             --CreatedItem.name_14_B3814BBE478D1FA0AB005BB6386C1541 = FName("drive")
--             --CreatedItem.object_18_519B13C4426D465A5A4A80A9FFFBB161 = Class
--             --CreatedItem.asProp_21_D3F8D96740005CA84664FBAD4E0F5F48 = FName("")
--             --CreatedItem.category_24_257ED6AB4855F44C55FFC98ECEA1F511 = 6
--             --CreatedItem.subcategory_35_BC2B1FF94CA9FC340ADDC78FFA014589 = FText("Electronics")
--             --CreatedItem.size_30_C3131BE84D89E0C389F1DB9557E08D74 = 1
--             --CreatedItem.achievementUnlock_38_883E827740DCBD0E996CF9B74B755175 = FName("")
--             --CreatedConsole.time_7_E02F9C514C9048F7B4AA4E82388D6DAE = 0.0
--             --CreatedConsole.items_3_C1FD2F664A7CE19ACFEB6DA0AF4F9927 = {CreatedItem}

--             ---@class Fstruct_store
--             local item_table = {
--                 ["price_11_BE3AF83E446D1C3BDEA63BA50CFE096C"] = 2,
--                 ["name_14_B3814BBE478D1FA0AB005BB6386C1541"] = FName("drive"),
--                 ["object_18_519B13C4426D465A5A4A80A9FFFBB161"] = Class,
--                 ["asProp_21_D3F8D96740005CA84664FBAD4E0F5F48"] = FName(""),
--                 ["category_24_257ED6AB4855F44C55FFC98ECEA1F511"] = 6,
--                 ["subcategory_35_BC2B1FF94CA9FC340ADDC78FFA014589"] = FText("Electronics"),
--                 ["size_30_C3131BE84D89E0C389F1DB9557E08D74"] = 1,
--                 ["achievementUnlock_38_883E827740DCBD0E996CF9B74B755175"] = FName(""),
--             }
--             --CreatedItem:Set(item_table)
--             ---@class Fstruct_storeOrder
--             local order_table = {
--                 ["time_7_E02F9C514C9048F7B4AA4E82388D6DAE"] = 0.0,
--                 ["items_3_C1FD2F664A7CE19ACFEB6DA0AF4F9927"] = {item_table},
--             }
--             --CreatedConsole:Set(order_table)
--             drone.sendShop({{laptop.storeSlots[1].Data}, 0.0})

--             --CreatedConsole:Set()
--             --if lmfaofunny ~= nil then
--             --    drone.sendShop(lmfaofunny)
--             --end

--             -- local order = laptop.storeSlots
--             -- order:ForEach(function(index, slot)
--             --     print(tostring(slot.Data))
--             -- end)

--             -- print("doohucieky")
--             -- print(CreatedItem:GetOuter():GetFullName())
--             -- print(CreatedItem:GetClass():GetFullName())
--             -- print(CreatedItem:GetFullName())

--             -- print(CreatedConsole:GetOuter():GetFullName())
--             -- print(CreatedConsole:GetClass():GetFullName())
--             -- print(CreatedConsole:GetFullName())

--             -- local my_int = CreatedItem:GetAddress()
--             -- local hex_uppercase = string.format("%X", my_int)
--             -- print(hex_uppercase) -- Output: ff
--             -- my_int = CreatedConsole:GetAddress()
--             -- hex_uppercase = string.format("%X", my_int)
--             -- print(hex_uppercase) -- Output: FF

--             --drone.sendShop(CreatedConsole)
--         end
--     end
-- end

-- function SendViaDroneReal()
--     local drone_class = StaticFindObject("/Game/objects/drone.drone_C")
--     local drone = FindObject(drone_class, GetWorld(), "drone", true)

--     local laptop = FindFirstOf("ui_laptop_C")

--     if laptop:IsValid() and drone:IsValid() then
--         drone.sendShop({{[1]=laptop.storeSlots[1].Data}, 0.0})

--         local order = laptop.storeSlots
--         order:ForEach(function(index, slot)
--             print(tostring(slot.Data))
--         end)

--         print("bunge")
--     end
-- end

--MakePlayerLookAt({["X"] = 0.0,["Y"] = 0.0,["Z"] = 0.0})
function MakePlayerLookAt(look_here)
    local Pawn = GetPawn()
    local Location = Pawn:K2_GetActorLocation()
    Pawn:makeLookAt(look_here,Location)
end

function MakePlayerDropItem()
    local Pawn = GetPawn()
    Pawn:forceDrop()
end

function MakePlayerEatShit(dmg)
    local Pawn = GetPawn()
    Pawn:ateShit(dmg)
end

function MakePlayerEatPiss(heal)
    local Pawn = GetPawn()
    Pawn:heal(heal)
end

function MakePlayerPassOut()
    local Pawn = GetPawn()
    Pawn:wakeup(true)
end

--??? only really makes you reset camera
function MakePlayerWakeUp()
    local Pawn = GetPawn()
    Pawn:forceWakeup()
end

function MakePlayerInexplicablyDie()
    local Pawn = GetPawn()
    Pawn:ragdollMode(true, false, true)
end

function MakePlayerBurn(duration)
    local Pawn = GetPawn()
    Pawn:ignite(duration)
end

--trap? can be escaped by ragdolling
function MakePlayerStop()
    local Pawn = GetPawn()
    Pawn:ladderOn()
end

--trap
function MakePlayerPause()
    local Pawn = GetPawn()
    Pawn:simulateEsc()
end

function MakePlayerWalk()
    local Pawn = GetPawn()
    Pawn:unrun()
end

function MakePlayerLoseInput()
    local Pawn = GetPawn()
    Pawn.input_forward = false
    Pawn.input_back = false
    Pawn.input_right = false
    Pawn.input_left = false
    Pawn.input_run = false
    Pawn.input_alt = false
    Pawn.input_jump = false
    Pawn.input_crouch = false
end

--can be a trap or a buff :)
function MakePlayerChangeArm(length)
    length = length or 100 -- ~100 is the default
    local Pawn = GetPawn()
    Pawn.armLength = length
end

function MakePlayerChangeSensitivity(speed)
    speed = speed or 1 -- 1 is the default
    local Pawn = GetPawn()
    Pawn.mouseSens = speed
end

function MakePlayerStrong(boolean)
    boolean = boolean or false -- false is the default
    local Pawn = GetPawn()
    Pawn.hulkMode = boolean
end

function MakePlayerFlingItem()
    local Pawn = GetPawn()
    Pawn.grabLen = 10000.0
    Pawn.grab_speed = 0.0001
end

function MakePlayerMirrorMouse()
    local Pawn = GetPawn()
    Pawn.isMirror = true
end

--??? makes it so you cant put up the item you are holding
function MakePlayerUnableToStash()
    local GameMode = GetGameMode()
    if GameMode:IsValid() then
        GameMode:fuckYOuItem()
    end
end

function MakePlayerRagdoll()
    local Pawn = GetPawn()
    Pawn:ragdollMode(true, false, false)
end

--trap ; make player reset radio tower
function MakePlayerLoseRadioTower()
    local dnc = StaticFindObject("/Game/objects/radiotower.radiotower_C")
    local danc = FindObject(dnc, GetWorld(), "radiotower", true)

    if danc:IsValid() then
        danc.breakdown()
        danc.breakdown()
        danc.breakdown()
    end
end

function MakePlayerLoseTransformers()
    local ActorInstances = FindAllOf("generator_C")
    if ActorInstances then
        for Index, ActorInstance in pairs(ActorInstances) do
            ActorInstance.IsBroken = true
        end
    end
end

function SwapToLevel(Levelname)
    GetGameplayStatics():OpenLevel(GetWorld(), FName(Levelname), false, "")
end

EmailUsername = {
    ["Bao"] = 0,
    ["Lea"] = 1,
    ["Auto"] = 2,
    ["Max"] = 3,
    ["Ken"] = 4,
    ["Ena"] = 5,
    ["Ula"] = 6,
    ["Ler"] = 7,
    ["user"] = 8,
    ["Noa"] = 9,
    ["blank"] = 10
}
function AddEmail(title, text, username)
    local laptop = FindFirstOf("ui_laptop_C")
    if laptop:IsValid() then
        local the_email = {
            ["new_14_5FB7784E4E60A05C8BC13ABD93D6EFDF"] = true,
            ["pfp_2_286B75414BAC856FBED047B8BE9F0065"] = nil,
            ["username_18_778252D64AB06BB5D3FBC386EC59383F"] = username,
            ["date_8_932438DD4158A22517E43E8DAD3BBC45"] = nil,
            ["topic_17_91E2F92C4DC4FF16CFAF539A3561F74B"] = FText(title),
            ["text_11_B74A8FDC40C1F46E42A9F382C0EFA6FF"] = FText(text),
        }
        laptop.addEmail(the_email)
    end
end

HintType = {
    ["Info"] = 0,
    ["Warning"] = 1,
    ["Error"] = 2,
    ["Thought"] = 3,
    ["Empty"] = 4
}
function AddHint(text, type)
    local GameMode = GetGameMode()
    if GameMode:IsValid() then
        GameMode['Add Hint from Gamemode'](GameMode, FText(text), type, false)
    end
end

function GiveItem(itemname, transform)
    local GameMode = GetGameMode()
    local Pawn = GetPawn()
    if GameMode:IsValid() and Pawn:IsValid() then
        local out = {}
        print("Giving " .. itemname)
        GameMode:spawnPropThroughGamemode(
            FName(itemname),
            { ["Translation"] = Pawn:K2_GetActorLocation(), ["Scale3D"] = { ["X"] = 1.0, ["Y"] = 1.0, ["Z"] = 1.0 } },
            1,
            out
        )
        out["actor "].Key = FName("APItem")
        if transform ~= nil then transform(out["actor "]) end
        Pawn:putObjectInventory2(out["actor "], false, {})
    end
end

function ShowAchievementPopup(type, name, progressTarget, target)
    local GameMode = GetGameMode()
    if GameMode:IsValid() then
        local data = {
            ["name_4_0534A17545E554F4B68649B89423EB76"] = FName(name),
            ["image_20_0E252F6A4A1A655ECB0689A250A2EB57"] = nil,
            ["displayName_5_B400DAF547199398CDA692B5B2D6A599"] = FText(name),
            ["progressTarget_11_43B369D14FAD25B027282CAFFC2C3879"] = progressTarget,
            ["progress_8_16978C8F431AF43A377F3BA52100DF7A"] = target,
            ["desc_14_416AEAFF42C88E5C34C4DA9EC2040435"] = FText("This is a test achievement"),
            ["award_17_BF5ED5C148773720D6813BB3F829CC90"] = 0
        }
        --0 == achievement
        --1 == advancement
        GameMode:addAchievementPopup(data, type)
    end
end

upgradeFullNames = {
    ["downloadSpd"] = {"upg_downloadSpd_3_BA98109842B6F6B10305FAAF5A3BBBF4", "upgrade_downloadSPeed"},
    ["processLvl"] = {"upg_processLvl_14_FA6136B44E749353CEF771AB0493F1A8", "upgrade_computerLvl"},
    ["processSpeed"] = {"upg_processSpeed_99_71FB42F64E4B845C653191A399690DB0", "upgrade_computerSPeed"},
    ["coordDrift"] = {"upg_coordDrift_95_A557469147F2A7F09452AFBD87AE4D20", "upgrade_sensorDrift"},
    ["coordPingSpeed"] = {"upg_coordPingSpeed_98_1F24EADD4D27B653A932A48987669FCB", "upgrade_pingSpeed"},
    ["coordMovementSpeed"] = {"upg_coordMovementSpeed_97_16B378034FDC97CB0628CBABB7674074", "upgrade_sensorSpeed"},
    ["coordCooldown"] = {"upg_coordCooldown_77_DFB1A6684A3BDDFEF94C6689D37CD2E8", "upgrade_cooldown"},
    ["scanner"] = {"upg_scanner_25_672849B8449E51A274C37DA92AD8B544", "upgrade_sensor"},
    ["triangleProb"] = {"upg_triangleProb_103_C4D06BDA4C93B8ADC417EDA7DE68FA73", "upgrade_pingStrength"},
    -- Filler
    ["coordRadarSpeed"] = {"upg_coordRadarSpeed_96_FBB3C8E541C23756B2F8A294D600F145", "upgrade_coordinateSpeed"},
    ["radarHist"] = {"upg_radarHist_93_3D85E50D4EA72B5864C6E0815C87CEB7", "upgrade_radarHist"},
    ["radar"] = {"upg_radar_speed_94_F1113DC149FA8DC9995F8EBAF2C7A452", "upgrade_radarSpd"},
    ["compTime"] = {"upg_compTime_69_7728FF794AD678EC9B481B840C119A20", "upgrade_breakerSpeed"},
    ["detecQual"] = {"upg_detecQual_54_0111E1654106C524D03278820389DDB3", "upgrade_deteQ"},
    ["scannerFr"] = {"upg_scannerFr_28_D57F12F148F3BE477D20A4A1494A8D62", "upgrade_sensor_fr"},
    -- Unused
    ["downloadFiltSize"] = {"upg_downloadFiltSize_100_4219D6DB44F558ABA055C7B749BDBCAD", nil},
    ["serverStability"] = {"upg_serverStability_13_4A619D224CE31D9B70EF93977E4491CB", nil},
    ["transformer"] = {"upg_transofrmer_66_A09469B64370DD7DC7F940B0FF8B2C13", nil},
}
function Upgrade(name)
    local fullNames = upgradeFullNames[name]
    if not fullNames then return false end

    local GameMode = GetGameMode()
    if not GameMode:IsValid() then return false end

    local SaveGameObject = GameMode.saveSlot
    if not SaveGameObject:IsValid() then return false end

    local current = SaveGameObject.upgrades[fullNames[1]]
    SaveGameObject.upgrades[fullNames[1]] = current + 1

    local laptop = FindFirstOf("ui_laptop_C")
    if laptop:IsValid() and fullNames[2] then
        laptop[fullNames[2]]:upd()
    end

    return true
end

function LockUpgradeControls(laptop, item_name)
    local upgrade = item_to_upgrade[item_name]
    if not upgrade then return end
    print("Disabling controls of " .. upgrade)
    local compName = upgradeFullNames[upgrade][2]
    laptop[compName].button_upgDown:SetVisibility(2) -- Hidden
    laptop[compName].button_upgUp:SetVisibility(2) -- Hidden
end

function LockShopItemsAndRecipes(storeDatatable, recipesDatatable, propDatatable, item_names)
    local propAsItems = {}
    propDatatable:ForEachRow(function(name, data)
        for item, _ in pairs(item_names) do
            if string.lower(data.displayName_8_FE83ADBF40AA162942FCE589F5806DD2:ToString()) == string.lower(item) then
                if not itemToProps[item] then itemToProps[item] = {} end
                table.insert(itemToProps[item], name)
            end
        end
    end)
    for _, list in pairs(itemToProps) do
        for i, v in ipairs(list) do
            table.insert(propAsItems, v)
        end
    end
    print("Total items to check: " .. #propAsItems)
    storeDatatable:ForEachRow(function(name, data)
        local achievement = data.achievementUnlock_38_883E827740DCBD0E996CF9B74B755175:ToString()
        if array_contains(propAsItems, name) then
            if string.startswith(achievement, "__APLOCK__") then
                print(name .. " is already disabled")
            else
                print("Disabling " .. name .. " from shop")
                data.achievementUnlock_38_883E827740DCBD0E996CF9B74B755175 = FName("__APLOCK__" .. achievement)
            end
        end
    end)
    recipesDatatable:ForEachRow(function(name, data)
        local result = data.result_6_893C01EE4438C4AAF7E917954BB7F448
        if #result < 1 then return end
        local fname = result[1]:ToString()
        if array_contains(propAsItems, fname) then
            local blueprint = data.blueprint_9_1946A61745B0008C0F2F268F1D73DB38:ToString()
            if string.startswith(blueprint, "__APLOCK__") then
                print(name .. " is already disabled")
            else
                print("Disabling " .. name .. " recipe")
                data.blueprint_9_1946A61745B0008C0F2F268F1D73DB38 = FString("__APLOCK__" .. blueprint)
            end
        end
    end)
end

local recipeResultToItemName = {
    ["scrap_plastic"] = "Plastic Scrap Recipe",
    ["scrap_metal"] = "Metal Scrap Recipe",
    ["scrap_elec"] = "Electronic Scrap Recipe",
    ["scrap_glass"] = "Glass Scrap Recipe",
    ["scrap_rubber"] = "Rubber Scrap Recipe",
    ["scrap_paper"] = "Paper Scrap Recipe",
    ["scrap_wood"] = "Wood Scrap Recipe",
    ["scrap_rubble"] = "Rubble Recipe",
}
function LockRecipes(datatable, item_names)
    datatable:ForEachRow(function(name, data)
        local result = data.result_6_893C01EE4438C4AAF7E917954BB7F448
        if #result < 1 then return end
        local fname = result[1]:ToString()
        local item = recipeResultToItemName[fname]
        if item and item_names[item] then
            local blueprint = data.blueprint_9_1946A61745B0008C0F2F268F1D73DB38:ToString()
            if string.startswith(blueprint, "__APLOCK__") then
                print(name .. " is already disabled")
            else
                print("Disabling " .. name .. " recipe")
                data.blueprint_9_1946A61745B0008C0F2F268F1D73DB38 = FString("__APLOCK__" .. blueprint)
            end
        end
    end)
end

entrance_to_door = {
    ["Alpha Base Entrance"] = "basedoor_entrance",
    ["Signal Lab Entrance"] = "basedoor_signalroom",
    ["Server Room Entrance"] = "basedoor_serverroom",
    ["Garage Entrance"] = "basedoor_garage",
    ["Admin Room Entrance"] = "basedoor_security",
    ["Break Room Entrance"] = "basedoor_breakroom",
    ["Utility Closet Entrance"] = "basedoor_closet",
    ["Alpha Stairs Entrance"] = "basedoor_staircase",
    ["Storage Room Entrance"] = "basedoor_upperLift",
    ["Staff Room Entrance"] = "basedoor_bedroom",
    ["Bathroom Entrance"] = "basedoor_bathroom",
    ["Alpha Roof Entrance"] = "basedoor_balcony",
    ["Bunker Entrance"] = "alphaBunkerDoor",

    -- Kept here for the auto_item
    ["TR1 Room Entrance"] = "",
    ["TR2 Room Entrance"] = "",
    ["TR3 Room Entrance"] = ""
}
function LockDoors(item_names)
    local doors_to_lock = {}
    for item, _ in pairs(item_names) do
        if string.match(item, "^TR. Room Entrance$") then
            -- Transformer doors have generated keys, so we must use something else to get them
            local index = tonumber(item:sub(3,3))
            for _, tr in ipairs(FindAllOf("generatorBuilding_C")) do
                if tr.trNum == index - 1 then
                    if tr.door2.ChildActor.superClosed then
                        print("Door of TR" .. index .. " was already jammed")
                    else
                        print("Jamming door of TR" .. index)
                        tr.door2.ChildActor.superClosed = true
                    end
                end
            end
        else
            local door = entrance_to_door[item]
            if door then
                doors_to_lock[door] = true
            end
        end
    end

    for _, door in ipairs(FindAllOf("door_C")) do
        if doors_to_lock[door.Key:ToString()] then
            if door.superClosed then
                print("Door " .. door.Key:ToString() .. " was already jammed")
            else
                print("Jamming door " .. door.Key:ToString())
                door.superClosed = true
            end
        end
    end
end

item_to_breaker = {
    ["Processing Breaker"] = {"calculcations", "text_calc", "breakerComp_calc", "Processing", "press_calc"},
    ["Download Breaker"] = {"download", "text_downloading", "breakerComp_down", "Download", "press_downl"},
    ["Coordinates Breaker"] = {"coordinates", "text_coords", "breakerComp_coord", "Coordinates", "press_coord"},
    ["Playing Breaker"] = {"playing", "text_playing", "breakerComp_play", "Playing", "press_play"}
}
function LockBreakers(laptop, power_control, item_name)
    local data = item_to_breaker[item_name]
    if data then
        print("Locking " .. item_name)
        locked_breakers[data[1]] = true
        power_control[data[2]]:SetText(FString("[BROKEN]"))
        laptop[data[3]].DisplayName = FText("[BROKEN]")
    end
end

function CheckUnobtainableWorldItemLocations()
    local missing_keynames = {}
    local total = 0
    for _, id in ipairs(MissingLocations) do
        local name = GetAPNamefromLocationID(id)
        if name ~= nil then
            -- print("name: " .. tostring(name))
            local keyname = inverse_locations[name]
            if keyname ~= nil and not lock_until_ap_item[keyname] then
                -- print("keyname: " .. tostring(keyname))
                missing_keynames[keyname] = name
                total = total + 1
            end
        end
    end
    local props = FindAllOf("prop_C")
    local buried_items = FindAllOf("dirthole_item_C")
    if props and buried_items then
        print("Checking " .. total .. " potential missing key names against " .. #props .. " props and " .. #buried_items .. " buried items")
        for _, prop in ipairs(props) do
            if missing_keynames[prop.Key:ToString()] then
                total = total - 1
                missing_keynames[prop.Key:ToString()] = nil
            elseif missing_keynames[prop.Name:ToString()] then
                total = total - 1
                missing_keynames[prop.Name:ToString()] = nil
            end
        end
        for _, prop in ipairs(buried_items) do
            if missing_keynames[prop.Key:ToString()] then
                total = total - 1
                missing_keynames[prop.Key:ToString()] = nil
            elseif missing_keynames[prop.Name:ToString()] then
                total = total - 1
                missing_keynames[prop.Name:ToString()] = nil
            end
        end

        if total > 0 then
            AddHint("You are missing " .. total .. " locations whose world items couldn't be found", HintType.Warning)
            for keyname, _ in pairs(missing_keynames) do
                print(keyname)
            end
            ExecuteWithDelay(2000, function()
                AddHint("Releasing those locations as a fallback measure", HintType.Warning)
                for _, name in pairs(missing_keynames) do
                    print(name)
                    SendLocation(name)
                end
            end)
        end
    else
        AddHint("Failed to verify if missing world item locations still exist", HintType.Error)
    end
end

function CheckShopAndControlsUnlock(name, show_hint)
    local group = {name, group = name}
    for _, possible_group in ipairs(unlockGroups) do
        if array_contains(possible_group, name) then
            group = possible_group
            break
        end
    end
    local count = 0
    for _, val in ipairs(group) do
        count = count + (slot_data.ItemNames[val] or 0)
    end
    if count > 0 then
        count = count - 1
        slot_data.ItemNames[name] = slot_data.ItemNames[name] - 1
        local props = itemToProps[group.group]
        local upgrade = item_to_upgrade[group.group]
        if count == 0 then
            if props then 
                UnlockShopItems(props, show_hint)
                for _, prop in ipairs(props) do UnlockRecipe(prop) end
            end
            if upgrade then EnableUpgradeControls(upgrade, show_hint) end
        else
            print("Still missing " .. count .. " " .. group.group .. " to unlock shop")
        end
    end
end

function UnlockBreaker(item_name)
    local laptop = FindFirstOf("ui_laptop_C")
    local power_control = FindFirstOf("powerControl_C")
    if laptop:IsValid() and power_control:IsValid() then
        local data = item_to_breaker[item_name]
        if data then
            print("Unlocking " .. item_name)
            locked_breakers[data[1]] = false
            power_control[data[2]]:SetText(FString(data[4]))
            laptop[data[3]].DisplayName = FText(data[4])
        end
    else
        AddHint("Failed to unlock breaker", HintType.Error)
    end
end

function UnlockDoor(item_name)
    if string.match(item_name, "^TR. Room Entrance$") then
        -- Transformer doors have generated keys, so we must use something else to get them
        local index = tonumber(item_name:sub(3, 3))
        for _, tr in ipairs(FindAllOf("generatorBuilding_C")) do
            if tr.trNum == index - 1 then
                print("Unjamming door of TR" .. index)
                tr.door2.ChildActor.superClosed = false
            end
        end
        return
    end

    for _, door in ipairs(FindAllOf("door_C")) do
        if door.Key:ToString() == entrance_to_door[item_name] then
            print("Unjamming door " .. door.Key:ToString())
            door.superClosed = false
        end
    end
end

function UnlockRecipe(recipe_or_result_name)
    local datatable = StaticFindObject("/Game/main/datatables/list_craftRecipes.list_craftRecipes")
    if datatable:IsValid() then
        datatable:ForEachRow(function(name, data)
            local result = data.result_6_893C01EE4438C4AAF7E917954BB7F448
            if #result < 1 then return end
            local fname = result[1]:ToString()
            local unlock_name = recipeResultToItemName[fname] or fname
            if unlock_name == recipe_or_result_name then
                local blueprint = data.blueprint_9_1946A61745B0008C0F2F268F1D73DB38:ToString()
                if string.startswith(blueprint, "__APLOCK__") then
                    print("Enabling " .. name .. " recipe")
                    data.blueprint_9_1946A61745B0008C0F2F268F1D73DB38 = FString(string.sub(blueprint, string.len("__APLOCK__") + 1))
                else
                    print(name .. " is already enabled")
                end
            end
        end)
    else
        AddHint("Failed to unlock recipe " .. recipe_or_result_name, HintType.Error)
    end
end

function UnlockShopItems(props, show_hint)
    local storeDatatable = StaticFindObject("/Game/main/datatables/list_store.list_store")
    if storeDatatable:IsValid() then
        storeDatatable:ForEachRow(function(name, data)
            local achievement = data.achievementUnlock_38_883E827740DCBD0E996CF9B74B755175:ToString()
            if array_contains(props, name) then
                if string.startswith(achievement, "__APLOCK__") then
                    print("Enabling " .. name .. " in shop")
                    data.achievementUnlock_38_883E827740DCBD0E996CF9B74B755175 = FName(string.sub(achievement, string.len("__APLOCK__") + 1))
                else
                    print(name .. " is already enabled")
                end
            end
        end)
        if show_hint then
            AppendItemsHint(" (Shop item unlocked)", true)
        end
    else
        AddHint("Failed to unlock shop item", HintType.Error)
    end
end

function EnableUpgradeControls(upgrade, show_hint)
    print("Enabling controls of " .. upgrade)
    local laptop = FindFirstOf("ui_laptop_C")
    if laptop:IsValid() then
        local compName = upgradeFullNames[upgrade][2]
        laptop[compName].button_upgDown:SetVisibility(0) -- Visible
        laptop[compName].button_upgUp:SetVisibility(0) -- Visible
        if show_hint then
            AppendItemsHint(" (Upgrade controls restored)", true)
        end
    else
        AddHint("Failed to enable upgrade controls", HintType.Error)
    end
end

function TryToBlowoutRandomFuse()
    local can_blow_out = {}
    local radiotower = FindFirstOf("radiotower_C")
    radiotower.fuses:ForEach(function(i, e)
        if e:get() == 1 then
            table.insert(can_blow_out, radiotower)
            return true
        end
    end)
    local coordRadars = FindAllOf("coordRadarDish_C")
    for _, radar in ipairs(coordRadars or {}) do
        radar.fuses:ForEach(function(i, e)
            if e:get() == 1 then
                table.insert(can_blow_out, radar)
                return true
            end
        end)
    end
    print("Can blow out: " .. #can_blow_out)
    if #can_blow_out == 0 then
        return false
    end
    local index = math.random(1, #can_blow_out)
    print(can_blow_out[index]:GetFullName())
    can_blow_out[index]:breakdown()
    return true
end
