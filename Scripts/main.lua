print("[MyLuaMod] Mod loaded\n")

UEHelpers = require("UEHelpers")

require("utils")
require("game_utils")
require("save")
require("archipelago")

--last achieved day
local latest_day = 0

--currently active task
local task_active = false

--active fuse count
local fuses = {}
local fuse_debt = {}

--ap day items
have_days = 0

items_hint = ""
items_hint_type = HintType.Info

looking_at_location = -1

local last_item_failed = false

DELETE_LOCATION_ITEMS = true

-- TODO: Find better name
function CheckAutoItem(i)
    if i < #item_list then
        local next_item = item_list[i+1]
        local item_name = GetAPItemNameFromId(next_item.item)
        if WasSkipClaimed(item_name) then
            ShiftSkipClaimed()
            return CheckAutoItem(i+1)
        end
        local auto_item = auto_map[item_name]
        if auto_item ~= nil then
            items_hint = items_hint .. item_name .. " from " .. ap:get_player_alias(next_item.player) .. "\n"
            UpdateItemsHintType(auto_item.hint)
            auto_item.run()
            CheckShopAndControlsUnlock(item_name, true)
            return CheckAutoItem(i+1)
        end
    end
    SetRecievedItems(i)
    SendItemsHint()
end

function AppendItemsHint(msg, same_line)
    if #items_hint == 0 then
        items_hint = msg
    else
        if not same_line then msg = "\n" .. msg end
        items_hint = items_hint .. msg
    end
end

function UpdateItemsHintType(hint_type)
    if (
        hint_type == HintType.Error
        or hint_type == HintType.Warning and items_hint_type ~= HintType.Error
        or hint_type == HintType.Thought and items_hint_type ~= HintType.Error and items_hint_type ~= HintType.Warning
    ) then
        items_hint_type = hint_type
    end
end

function SendItemsHint()
    local item_count = 0
    for i=GetRecievedItems()+1,#item_list do
        local item = item_list[i]
        local item_name = GetAPItemNameFromId(item.item)
        if not WasSkipClaimed(item_name) then
            item_count = item_count + 1
        end
    end
    if item_count > 0 then
        local item = item_list[GetRecievedItems()+1]
        local item_name = GetAPItemNameFromId(item.item)
        local player = ap:get_player_alias(item.player)
        if #items_hint > 0 then
            items_hint = items_hint .. "\n\n"
        else
            UpdateItemsHintType(HintType.Warning)
        end
        AddHint(items_hint .. "You have " .. tostring(item_count) .. " unclaimed item(s).\nNext item is " .. item_name .. " from " .. player .. "\nPress F9 to claim.", items_hint_type)
    else
        if #items_hint > 0 then
            items_hint = items_hint .. "\n"
        end
        AddHint(items_hint .. "You have recieved all items. Yay!", items_hint_type)
    end
    items_hint = ""
    items_hint_type = HintType.Info
end

function GetNextItem()
    local i = GetRecievedItems()
    if i < #item_list then
        local item = item_list[i+1]
        if item.index >= i then
            local item_name = GetAPItemNameFromId(item.item)
            local player = ap:get_player_alias(item.player)
            AppendItemsHint(item_name .. " from " .. player, false)
            local complex_item = complex_item_map[item_name]
            if complex_item then
                complex_item()
            else
                local internal_name = inverse_item_map[string.lower(item_name)]
                if internal_name ~= nil then
                    GiveItem(internal_name)
                elseif last_item_failed then
                    AddHint("Item skipped", HintType.Warning)
                    last_item_failed = false
                else
                    AddHint("Item unsupported. :)\nYou may stop your run here and report this to the maintainers,\nor press F9 again to skip this item\nIt will be lost forever if you do so", HintType.Error)
                    last_item_failed = true
                    return
                end
            end
            CheckShopAndControlsUnlock(item_name, true)
            CheckAutoItem(i+1)
        end

        local laptop = FindFirstOf("ui_laptop_C")
        if laptop:IsValid() then
            laptop:genStore()
        end
    else
        SendItemsHint()
    end
end

RegisterKeyBind(Key.F9, function()
    ExecuteInGameThread(function()
        GetNextItem()
    end)
end)

function OnTouchProp(prop)
    local key = prop.Key:ToString()
    -- Prevent items given by AP from triggering checks
    if string.startswith(key, "APItem") then return false end
    local name = prop.Name:ToString()
    local location = locationKeys[key] or locationKeys[name]
    if not location then return false end
    local collected = false
    local checkedNames = GetCheckedLocationNames()
    if array_contains(checked_location_names, location) then
        print("Previously checked!")
        collected = true
        for _, name in ipairs(checkedNames) do
            if name == keyname then
                print("Registered on this save")
                collected = false
                return false
            end
        end
        if collected then
            AddHint("You already collected that item!", HintType.Warning)
        end
    else
        print("Sending check")
        collected = SendLocation(location)
    end

    local destroyItem = false
    if collected then
        AddCheckedLocationName(location)
        if preserve_items[name] then
            prop.Key = FName("APItem")
        elseif DELETE_LOCATION_ITEMS then
            destroyItem = true
        end
    elseif lock_until_ap_item[name] and any(item_list, function(val) return GetAPItemNameFromId(val.item) == item_map[name] end) then
        destroyItem = true
        AddHint("You're not allowed to get this item until you receive it!", HintType.Error)
    end

    if destroyItem then
        -- Alternatives: interruptHoldItem, timeDrop, simulateDrop
        prop:K2_DestroyActor()
    end
    return destroyItem
end

function CheckDailyTask()
    local SaveGameObject = GetSaveSlot()
    if SaveGameObject ~= nil then
        local new_active = SaveGameObject.taskNew.active_15_4D2EB6A44AAAE79770E875BDC11E595B
        if task_active and not new_active then
            SendNextLocation("Daily Task Done")
        end
        print("DAILY TASK ACTIVE IS NOW " .. tostring(new_active))
        task_active = new_active
    end
end

function CheckFuseHealth(index, obj)
    if not obj:IsValid() then return 0 end
    local base = fuses[index] or {}
    fuses[index] = {}
    obj.fuses:ForEach(function(i, e) fuses[index][i] = e:get() end)

    old_health = 0
    old_broken = 0
    new_health = 0
    new_broken = 0
    for _, fuse in pairs(base) do
        if fuse == 1 then old_health = old_health + 1 elseif fuse == 2 then old_broken = old_broken + 1 end
    end
    for _, fuse in pairs(fuses[index]) do
        if fuse == 1 then new_health = new_health + 1 elseif fuse == 2 then new_broken = new_broken + 1 end
    end

    local broken_increase = new_broken - old_broken
    local increase = new_health - old_health
    local corrected_increase = increase + (broken_increase > 0 and broken_increase or 0)
    print(obj:GetFName():ToString() .. " health: " .. new_health .. " (" .. increase .. "," .. corrected_increase .. ")")
    fuse_debt[index] = fuse_debt[index] and fuse_debt[index] + corrected_increase or corrected_increase
    if fuse_debt[index] > 0 then
        corrected_increase = fuse_debt[index]
        fuse_debt[index] = 0
        return corrected_increase
    else
        return math.min(increase, 0)
    end
end

function CheckDeathLink()
    -- AddHint("You died!", HintType.Thought)
    if ap and death_link_enabled then
        death_link_enabled = false
        ap:Bounce({ cause = "", source = slot, time = os.time(os.date("!*t")) }, nil, nil, {"DeathLink"})
    end
end

function RegisterAllHooks()
    local Gamemode = GetGameMode()
    if Gamemode then
        -- Only run this on the actual map
        if Gamemode.isMainMenu then
            print("On main menu")
            return
        end
    else
        -- Can't verify map
        print("No gamemode")
        return
    end

    RegisterUniqueHook("/Game/objects/prop.prop_C:playerGrabbed_pre", function(self, player, collected)
        if OnTouchProp(self:get()) then
            player:get():dropGrabObject()
        end
    end)
    RegisterUniqueHook("/Game/objects/prop.prop_C:playerHoldPost", function(self, player, collected)
        if OnTouchProp(self:get()) then
            player:get():forceDrop()
        end
    end)
    RegisterUniqueHook("/Game/objects/prop.prop_C:playerTryToCollect", function(self, player, collected)
        OnTouchProp(self:get())
    end)
    RegisterUniqueHook("/Game/objects/prop.prop_C:player_use", function(self, player, collected)
        OnTouchProp(self:get())
    end)
    RegisterUniqueHook("/Game/objects/prop_container.prop_container_C:openContainer", function(self)
        if (OnTouchProp(self:get())) then
            GetGameMode().propInventory:Exit()
        end
    end)
    RegisterUniqueHook("/Game/objects/prop.prop_C:GetName", function(self, DisplayName, propname)
        local key = self:get().Key:ToString()
        if string.startswith(key, "APItem") then return end
        local name = self:get().Name:ToString()
        local location = locationKeys[key] or locationKeys[name]
        if location ~= nil then
            print("Found clientside location: " .. location)
            local id = GetAPLocationIDfromName(location)
            print("Serverside id: " .. tostring(id))
            if id ~= nil and id >= 0 then
                local missing = array_contains(MissingLocations, id)
                local scout = ScoutedLocations[id]
                if scout ~= nil then
                    DisplayName:set(FText("[AP] " .. scout.item .. " for " .. scout.player))
                elseif missing then
                    DisplayName:set(FText("[AP] Scouting..."))
                    ScoutLocationByName(location)
                    looking_at_location = id
                end
            end
        end
    end)

    local droneAtBase = false
    RegisterUniqueHook("/Game/objects/drone.drone_C:soundAlarm", function(self)
        print("Drone is now at base")
        droneAtBase = true
    end)
    RegisterUniqueHook("/Game/objects/drone.drone_C:triggerFly", function(self, console)
        print("Drone has begun flight")
        if not droneAtBase then return end
        droneAtBase = false
        print("Drone was at base")
        CheckDailyTask()

        local SaveSlot = GetSaveSlot()
        if SaveSlot ~= nil then
            local container_index = self:get().container.propInventory.Index
            local container_data = SaveSlot.GObjStack[container_index + 1].obj_11_89CC26B14C79E8F107FE6E9010A5AFC9
            local sold_garbage_bags = GetSoldGarbageBags()
            container_data:ForEach(function(_, item)
                local classname = item:get().class_3_5267A5ED44C89294283B8CBBEC685F8A:GetFName():ToString()
                print(classname)
                if classname == "prop_box_C" then
                    item:get().signals_45_CE5AB8DE4026B6660BF9A28FA6690AD5:ForEach(function(_, signal)
                        local sold = false
                        SaveSlot.soldSignals:ForEach(function(_, sold)
                            if sold:get():ToString() == signal:get().id_26_DD9E8AA643A0BF449C8D1E8993752C16:ToString() then
                                sold = true
                                return true
                            end
                        end)
                        if not sold and #signal:get().name_15_4DC53B564EDE34E0A8A16A92BD26B4AD:ToString() > 0 then
                            local level = signal:get().level_8_986E7CB3437BFD9FC9F6DF824C794EA8
                            if options.BackwardsSignalLevels == 1 then
                                for i=0,level do
                                    SendNextLocation("Sell Level " .. i .. " Signal")
                                end
                            else
                                SendNextLocation("Sell Level " .. level .. " Signal")
                            end
                        end
                    end)
                end

                if classname == "prop_garbageBag_C" then
                    sold_garbage_bags = sold_garbage_bags + 1
                end
            end)

            while sold_garbage_bags >= 24 do
                SendNextLocation("Sell 24 Full Trash Bags")
                sold_garbage_bags = sold_garbage_bags - 24
            end
            SetSoldGarbageBags(sold_garbage_bags)
        end
    end)
    RegisterUniqueHook("/Game/objects/droneSellLocation.droneSellLocation_C:sell", function(self, Points, responseEmail, checked, soldAmountSig, sellList)
        CheckDailyTask()
    end)

    RegisterUniqueHook("/Game/objects/serverBox.serverBox_C:fix", function(self)
        SendNextLocation("Repair Server")
    end)
    RegisterUniqueHook("/Game/objects/misc/coordRadarDish.coordRadarDish_C:updFuses", function(self)
        local increase = CheckFuseHealth(self:get().ID, self:get())
        local pending = GetPendingFuseBlowouts()
        if increase < 0 and pending > 0 then
            SetPendingFuseBlowouts(math.max(0, pending + increase))
        end
        for i=1,increase do
            SendNextLocation("Replace Fuse")
        end
    end)
    RegisterUniqueHook("/Game/objects/radiotower.radiotower_C:updFuses", function(self)
        local increase = CheckFuseHealth(3, self:get())
        local pending = GetPendingFuseBlowouts()
        if increase < 0 and pending > 0 then
            SetPendingFuseBlowouts(math.max(0, pending + increase))
        end
        for i=1,increase do
            SendNextLocation("Replace Fuse")
        end
    end)

    local generatorCycles = {}
    RegisterUniqueHook("/Game/objects/generator.generator_C:player_use", function(self)
        local index = self:get().Index
        local cycle = self:get().cycle
        if generatorCycles[index] ~= nil and generatorCycles[index] < 100 and cycle == 100 then
            SendNextLocation("Repair Transformer")
        end
        generatorCycles[index] = cycle
    end)

    RegisterUniqueHook("/Game/objects/misc/kitchen.kitchen_C:fix", function(self, clean, Player, sponge, Hit)
        SendLocation("Repair the Oven")
    end)
    RegisterUniqueHook("/Game/objects/prop_shower.prop_shower_C:cleanSponge", function(self, clean, Player, sponge, Hit)
        if self:get().clean >= 1.0 then SendLocation("Clean the Shower") end
    end)
    RegisterUniqueHook("/Game/objects/toilet.toilet_C:cleanSponge", function(self, clean, Player, sponge, Hit)
        if self:get().clean >= 1.0 then SendLocation("Clean the Toilet") end
    end)
    RegisterUniqueHook("/Game/objects/sink.sink_C:cleanSponge", function(self, clean, Player, sponge, Hit)
        if self:get().clean >= 1.0 then SendLocation("Clean the Sink") end
    end)

    for _, variety in ipairs({"shri", "mush", "pepp", "pine"}) do
        RegisterUniqueHook("/Game/objects/prop_cfood_pizzad_" .. variety .. ".prop_cfood_pizzad_" .. variety .. "_C:cookItem", function(self)
            SendLocation("Bake a Pizza")
        end)
    end
    RegisterUniqueHook("/Game/objects/prop_cfood_breadmold.prop_cfood_breadmold_C:cookItem", function(self)
        SendLocation("Bake Bread")
    end)
    RegisterUniqueHook("/Game/objects/prop_cookingFood_cookietray.prop_cookingFood_cookietray_C:cookItem", function(self)
        SendLocation("Bake Cookies")
    end)

    RegisterUniqueHook("/Game/objects/rockcandle.rockcandle_C:attemptIgnite", function(self)
        local pos = self:get():K2_GetActorLocation()
        local angle = (math.atan(pos.Y, pos.X) * 180 / math.pi + 360) % 360
        local dir
        print(self:get():GetFName():ToString() .. "/" .. pos.X .. "/" .. pos.Y .. ": " .. angle)
        if angle < 23 or angle >= 338 then
            dir = "East"
        elseif angle < 68 then
            dir = "Southeast"
        elseif angle < 113 then
            dir = "South"
        elseif angle < 158 then
            dir = "Southwest"
        elseif angle < 203 then
            dir = "West"
        elseif angle < 248 then
            dir = "Northwest"
        elseif angle < 293 then
            dir = "North"
        elseif angle < 338 then
            dir = "Northeast"
        end
        SendLocation("Light the " .. dir .. " Candle")
    end)

    RegisterUniqueHook("/Game/objects/greenfire.greenfire_C:extinguishFire", function(self)
        SendLocation("Extinguish the Green Fire")
    end)

    -- Day Looping
    RegisterUniqueHook("/Game/objects/misc/daynightCycle.daynightCycle_C:ReceiveTick", function(self, DeltaSeconds)
        if ap == nil then return end
        local SaveGameObject = GetSaveSlot()
        local danc = GetDNC()
        if danc:IsValid() and SaveGameObject ~= nil then
            --safe zone of time before next day
            if danc.Day >= danc.MaxTime - 5 and options.DayAsItems == 1 then
                --check if has next day
                if SaveGameObject.savedTime.Z + 1 > have_days then
                    AddHint('You do not have the next day! Looping...', HintType.Warning)
                    danc.Day = 0
                end
            end

            --do survived checks
            while SaveGameObject.savedTime.Z > latest_day do
                latest_day = latest_day + 1
                SendLocation("Survive Day " .. tostring(latest_day))
                if options and options.Objective == 6 and options.SurviveDay <= latest_day and not completed then
                    ReachGoal()
                end
            end
        end
    end)

    for cls, goal in pairs(createdGoals) do
        print("Setting up goal check for " .. cls)
        NotifyUniqueOnNewObject(cls, function(self)
            if ap == nil or completed then return end
            if goal == options.Objective then
                ReachGoal()
            end
        end)
    end
    RegisterUniqueHook("/Game/objects/warpbox.warpbox_C:player_use", function(self)
        if ap == nil or completed then return end
        if options.Objective ~= 5 then return end
        for index=1,9 do
            local has_tile = self:get().tiles[index]
            if not has_tile then return end
        end
        ReachGoal()
        self:get():Open(true)
        self:get().Out:Open(true)
    end)

    RegisterUniqueHook("/Game/main/mainGamemode.mainGamemode_C:setPower", function(self, active_calc, active_downl, active_coords, active_play, active_light)
        local Gamemode = GetGameMode()
        if Gamemode:IsValid() then
            if active_calc:get() and locked_breakers.calculations then Gamemode.eventer.event_solar:runTrigger(Gamemode, 0) end
            if active_downl:get() and locked_breakers.download then Gamemode.eventer.event_solar:runTrigger(Gamemode, 0) end
            if active_coords:get() and locked_breakers.coordinates then Gamemode.eventer.event_solar:runTrigger(Gamemode, 0) end
            if active_play:get() and locked_breakers.playing then Gamemode.eventer.event_solar:runTrigger(Gamemode, 0) end
        end
    end)

    RegisterUniqueHook("/Game/main/mainPlayer.mainPlayer_C:ragdollMode", function(self, ragdoll, passOut, death)
        if death:get() then CheckDeathLink() end
    end)

    -- RegisterUniqueHook("/Game/main/mainGamemode.mainGamemode_C:debugtp", function(self)
    --     local player = GetPawn()
    --     if player:IsValid() then
    --         player:teleportWObackrooms({ Translation = { X = -37692, Y = 69673, Z = 6480 } }, false, true) -- Game start position
    --         AddHint("Due to the AP mod, the Debug TP now brings you to the start of the game", HintType.Info)
    --     end
    -- end)
    -- RegisterUniqueHook("/Game/objects/prop_donut.prop_donut_C:ExecuteUbergraph_prop_donut", function(self, EntryPoint)
    --     local player = GetPawn()
    --     if player:IsValid() then
    --         player:teleportWObackrooms({ Translation = { X = -37692, Y = 69673, Z = 6480 } }, false, true) -- Game start position
    --         AddHint("Due to the AP mod, the donut now brings you to the start of the game", HintType.Info)
    --     end
    -- end)

    CheckDailyTask()
    local radiotower = FindFirstOf("radiotower_C")
    CheckFuseHealth(3, radiotower)
    local coordRadars = FindAllOf("coordRadarDish_C")
    for _, radar in ipairs(coordRadars or {}) do
        CheckFuseHealth(radar.ID, radar)
    end
    FillItemMap()

    local drone = FindFirstOf("drone_C")
    if drone:IsValid() then
        droneAtBase = drone.flyingType == 1
    end

    LoadNotebookData()
    LoopAsync(30000, function()
        if ap then return true end
        local Gamemode = GetGameMode()
        if Gamemode then
            -- Only run this on the actual map
            if Gamemode.isMainMenu then
                print("On main menu")
                return true
            end
        end
        AddHint("Remember to connect to Archipelago!", HintType.Thought)
        return false
    end)
end

RegisterKeyBind(Key.F8, {ModifierKey.CONTROL}, function()
    disconnect()
    ExecuteInGameThread(function()
        RegisterAllHooks()
    end)
end)

RegisterKeyBind(Key.F7, function()
    ExecuteInGameThread(function()
        AddHint("Debug shortcut", HintType.Warning)
        local notebook = FindAPNotebook()
        if notebook then
            AddHint("Found AP notebook", HintType.Warning)
            print(notebook)
        else
            AddHint("No notebook", HintType.Warning)
        end
        -- AppendItemsHint("A", false)
        -- AppendItemsHint("B", false)
        -- AppendItemsHint("C", false)
        -- SendItemsHint()
        -- print(GetGameMode().isMainMenu)
        -- print(GetGameMode():GetFullName())
        -- print(FindFirstOf("mainGamemode_C"):GetFullName())
        --LockBreakers({ ["Playing Breaker"] = 1 })
        --TryToBlowoutRandomFuse()
        --LockRecipes({"Metal Scrap Recipe"})
        --UnlockRecipe("Metal Scrap Recipe")
        --complex_item_map["Bunker Keycard"]()
        -- local pos = GetPawn():K2_GetActorLocation()
        -- print(pos.X .. "/" .. pos.Y .. "/" .. pos.Z)

        -- local storeDatatable = StaticFindObject("/Game/main/datatables/list_store.list_store")
        -- local propDatatable = StaticFindObject("/Game/main/datatables/list_props.list_props")
        -- if storeDatatable:IsValid() and propDatatable:IsValid() then
        --     result = "\n"
        --     storeDatatable:ForEachRow(function(name, data)
        --         result = result .. "    \"" .. propDatatable:FindRow(name).displayName_8_FE83ADBF40AA162942FCE589F5806DD2:ToString() .. "\": ShopItem(" .. data.price_11_BE3AF83E446D1C3BDEA63BA50CFE096C .. ", " .. data.size_30_C3131BE84D89E0C389F1DB9557E08D74 .. ", \"" .. name .. "\", IC.filler"
        --         if data.achievementUnlock_38_883E827740DCBD0E996CF9B74B755175:ToString() ~= "None" then result = result .. ", \"" .. data.achievementUnlock_38_883E827740DCBD0E996CF9B74B755175:ToString() .. "\"" end
        --         result = result .. "),\n"
        --     end)
        --     print(result)
        -- end
    end)
end)

RegisterUniqueHook("/Script/Engine.PlayerController:ClientRestart", function(self, NewPawn)
    NotifyUniqueOnNewObject("/Game/main/mainPlayer.mainPlayer_C", function(self)
        -- SetRecievedItems(0)
        ExecuteWithDelay(10, function() disconnect() end)
    end)

    local menu = FindFirstOf("ui_menu_C")
    if menu:IsValid() then
        local version = menu.txt_version.Slot.Parent.Slot.Parent.Slots[2].Content.Slots[2].Content.Text:ToString()
        print(version)
        if version ~= "a090n" then
            AddHint("The Archipelago mod is made to run on Build a090n (current is " .. version .. ").\nAny other version will most likely be unplayable.", HintType.Error)
        end
    end

    RegisterUniqueHook("/Game/main/mainGamemode.mainGamemode_C:Load Primitives", function(self, in_canLoad, in_isSubData, in_loadingSubLevel)
        if not in_loadingSubLevel:get() then
            RegisterAllHooks()
        else
            print("In sub level")
        end
    end)
end)

RegisterConsoleCommandHandler("host_timescale", function(FullCommand, Parameters)
    -- If we have no parameters then just let someone else handle this command
    if #Parameters < 1 then
        return false
    end

    local dnc = StaticFindObject("/Game/objects/misc/daynightCycle.daynightCycle_C")
    local danc = FindObject(dnc, GetWorld(), "daynightCycle", true)

    if danc:IsValid() then
        danc.TimeScale = tonumber(Parameters[1])
    end

    return true
end)

RegisterConsoleCommandHandler("connect", function(FullCommand, Parameters)
    if #Parameters < 2 then
        return false
    end
    local password = ""
    if #Parameters == 3 then
        password = Parameters[3]
    end
    connectToAp(Parameters[1], Parameters[2], password)
    return true
end)

RegisterConsoleCommandHandler("disconnect", function(FullCommand, Parameters)
    disconnect()
    return true
end)

RegisterConsoleCommandHandler("release", function(FullCommand, Parameters)
    SendLocation(Parameters[1])
    return true
end)

RegisterConsoleCommandHandler("panic", function(FullCommand, Parameters)
    if #Parameters < 1 then
        return false
    end
    for _, item in ipairs(item_list) do
        if item.flags & 1 > 0 then
            local item_name = GetAPItemNameFromId(item.item)
            if item_name == Parameters[1] then
                if auto_map[item_name] then
                    AddHint("You cannot replay auto redeemed items", HintType.Error)
                    return true
                end
                local complex_item = complex_item_map[item_name]
                if complex_item then
                    complex_item()
                    return true
                end
                local internal_name = inverse_item_map[string.lower(item_name)]
                if internal_name ~= nil then
                    AddHint("Giving " .. item_name, HintType.Info)
                    GiveItem(internal_name)
                    return true
                end
            end
        end
    end
    AddHint("Unknown or not yet received item\nNote: You can only panic in progression items", HintType.Error)
    return true
end)
