---@diagnostic disable: lowercase-global
---@diagnostic disable: undefined-global
---@diagnostic disable: undefined-field


--require "ItemManager"
--require "StaticObjectGetters"
--require "DatabaseInfo"
--require "ArchipelagoLists"

local AP = require("lua-apclientpp")

require("locations")
require("item_map")
require("utils")

-- global to this mod
local game_name = "Voices of the Void"
local items_handling = 7  -- receive everything
local client_version = {0, 6, 7}
local mod_version = {0, 7, 0}
local message_format = AP.RenderFormat.TEXT
---@type APClient
ap = nil
local LocationsToCheck = {}
local LocationsToScout = {}
ScoutedLocations = {}
MissingLocations = {}
CheckedLocations = {}

print("VOTV AP VERSION: " .. table.concat(mod_version, "."))

options = nil
slot_data = nil
completed = false
item_list = {}
checked_location_names = {}
server = nil
slot = nil 
password = nil
death_link_enabled = false
locked_breakers = {
    calculations = false,
    download = false,
    coordinates = false,
    playing = false
}

itemToProps = {
    ["Progressive Sleeping Bag"] = {"sleepingbag", "sleepingbag_br", "sleepingbag_st"},
    ["Progressive Camera"] = {"cam_h_0", "cam_h_1", "cam_h_2"},
    ["Scuba Gear"] = {"scuba", "scuba_t"},
    ["Kerfur"] = {"kerfus", "kerfus_0", "kerfus_1", "kerfus_2"},
    ["Half Hook"] = {"hook", "hook_h"},  -- We need to disable the full hook and single hook as well
    ["Hook"] = {"hook", "hook_h"},
}
unlockGroups = {
    {group = "Kerfur", "Blue Kerfur", "Pink Kerfur", "Red Kerfur"}
}

function connect(_server, _slot, _password)
    server = _server
    slot = _slot
    password = _password

    function on_socket_connected()
        AddHint("Socket connected", HintType.Info)
    end

    function on_socket_error(msg)
        print(msg)
        AddHint("Socket error: " .. tostring(msg), HintType.Error)
    end

    function on_socket_disconnected()
        AddHint("Socket disconnected", HintType.Error)
        item_list = {}
    end

    function on_room_info()
        AddHint("Room info", HintType.Info)
        ap:ConnectSlot(slot, password, items_handling, {"Lua-APClientPP"}, client_version)
    end

    function on_slot_connected(slot_data_remote)
        AddHint("Slot connected", HintType.Info)
        print("Locations checked: " .. table.concat(ap.checked_locations, ", "))
        print("Locations missing: " .. table.concat(ap.missing_locations, ", "))
        MissingLocations = ap.missing_locations
        slot_data = slot_data_remote
        options = slot_data.options

        for _, location_id in ipairs(ap.checked_locations) do
            CheckLocation(location_id)
        end

        if slot_data.Version then
            local mod_version_str = table.concat(mod_version, ".")
            local ap_version_str = table.concat(slot_data.Version, ".")
            local suffix = " (Mod: " .. mod_version_str .. ", AP: " .. ap_version_str .. ")"
            if slot_data.Version[1] ~= mod_version[1] then
                AddHint("Major version difference with the apworld!!" .. suffix, HintType.Error)
            elseif slot_data.Version[2] ~= mod_version[2] then
                AddHint("Minor version difference with the apworld!" .. suffix, HintType.Warning)
            elseif slot_data.Version[3] ~= mod_version[3] then
                AddHint("Revision difference with the AP" .. suffix, HintType.Info)
            end
        end

        local SaveGameObject = GetSaveSlot()
        if SaveGameObject ~= nil then
            if options.FunnySetting == 1 and not SaveGameObject.localGameRules.funnySetting_29_3DBB4B5041357E51DA0DFBAD9368E881 then
                AddHint("The AP includes funny items, but the setting is not enabled!", HintType.Error)
            end

            if options.TimeSensitive == 1 and SaveGameObject.savedTime.Z < 8 then
                AddHint("The Green Fire is enabled as a location, but it is not day 8+ yet!", HintType.Warning)
            end
        end

        if options.DeathLink == 1 then
            death_link_enabled = true
            ap:ConnectUpdate(nil, {"Lua-APClientPP", "DeathLink"})
        end

        local laptop = FindWithErrorHint("ui_laptop_C")
        local power_control = FindWithErrorHint("powerControl_C")
        local storeDatatable = StaticFindWithErrorHint("/Game/main/datatables/list_store.list_store")
        local recipesDatatable = StaticFindWithErrorHint("/Game/main/datatables/list_craftRecipes.list_craftRecipes")
        local propDatatable = StaticFindWithErrorHint("/Game/main/datatables/list_props.list_props")
        for name, _ in pairs(slot_data.ItemNames) do
            LockUpgradeControls(laptop, name)
            LockBreakers(laptop, power_control, name)
        end
        -- TODO: See how much those can be optimized, and also how much we can optimize replaying the items
        LockShopItemsAndRecipes(storeDatatable, recipesDatatable, propDatatable, slot_data.ItemNames)
        LockRecipes(recipesDatatable, slot_data.ItemNames)
        LockDoors(slot_data.ItemNames)
        CheckUnobtainableWorldItemLocations()
        
        -- Kill the breakers if any of them got locked and is active
        for _, data in pairs(item_to_breaker) do
            if locked_breakers[data[1]] and power_control[data[5]] then
                -- Calling the solar function doesn't play the solar event sound
                power_control:solar()
                break
            end
        end

        ap:StatusUpdate(AP.ClientStatus.PLAYING)
    end

    function on_slot_refused(reasons)
        AddHint("Slot refused: " .. table.concat(reasons, ", "), HintType.Error)
    end

    function on_items_received(received_items)
        print("Items received: " .. #received_items)
        local I = GetRecievedItems()
        local is_initial = #item_list == 0
        for _, item in ipairs(received_items) do
            table.insert(item_list, item)
            local name = GetAPItemNameFromId(item.item)

            local auto = auto_map[name]
            if auto and auto.replay and (item.index < I or WasSkipClaimed(name)) then
                print("Replaying " .. name)
                auto.run()
            end
            if item.index < I then
                CheckShopAndControlsUnlock(name, false)
            elseif auto and not is_initial then
                -- The only weird case is if the very first item is auto, but this gets handled a few lines below by CheckAutoItem
                AddSkipClaimedItem(name)
                items_hint = items_hint .. name .. " from " .. ap:get_player_alias(item.player) .. "\n"
                UpdateItemsHintType(auto.hint)
                auto.run()
                CheckShopAndControlsUnlock(name, true)
            end
        end

        print("Total items received: " .. #item_list)
        CheckAutoItem(I)

        local laptop = FindFirstOf("ui_laptop_C")
        if laptop:IsValid() then
            laptop:genStore()
        end
    end

    function on_location_info(infos)
        print("Locations scouted:")
        for _, info in ipairs(infos) do
            if ScoutedLocations[info.location] == nil then
                local item = ap:get_item_name(info.item, ap:get_player_game(info.player))
                local location = GetAPNamefromLocationID(info.location)
                print("scouted item " .. item .. " in location " .. location)
                if location == nil then
                    print("we sajdklajskl")
                else
                    local player = ap:get_player_alias(info.player)
                    ScoutedLocations[info.location] = { ["item"] = item, ["player"] = player }
                    if info.location == looking_at_location then
                        local ui = FindFirstOf("ui_UI_C")
                        if ui:IsValid() then
                            ui.text_hoverItemName:SetText(FText("[AP] " .. item .. " for " .. player))
                        end
                        looking_at_location = -1
                    end
                    if array_contains(LocationsToCheck, info.location) then
                        ShowAchievementPopup(1, item .. " for " .. player, 1, 1)
                    end
                end
            end
        end
    end

    function on_location_checked(locations)
        print("Locations checked:" .. table.concat(locations, ", "))
        print("Checked locations: " .. table.concat(ap.checked_locations, ", "))
        for _, LocationID in ipairs(locations) do
            CheckLocation(LocationID)
        end
    end

    function CheckLocation(location_id)
        CheckedLocations[location_id] = true
        table.insert(LocationsToCheck, location_id)
        local name = GetAPNamefromLocationID(location_id)
        if name ~= nil then
            table.insert(checked_location_names, name)
        end
    end

    function on_data_package_changed(data_package)
        print("Data package changed:")
        print(table.concat(data_package, ", "))
    end

    function on_print(msg)
        AddHint(msg, HintType.Thought)
    end

    function on_print_json(msg, extra)
        print(ap:render_json(msg, message_format))
        if extra.type == "Hint" and (extra.receiving == ap:get_player_number() or extra.finding == ap:get_player_number()) then
            AddEmail("Archipelago Hint", ap:render_json(msg, message_format), EmailUsername.Auto)
        end
    end

    function on_bounced(bounce)
        print("Bounced:")
        for k,v in pairs(bounce) do
            print(k .. ": " .. tostring(v))
        end
        if bounce.tags and array_contains(bounce.tags, "DeathLink") and death_link_enabled then
            local cause = #bounce.data.cause > 0 and bounce.data.cause or (bounce.data.source .. " died. What a shame!")
            AddHint(cause, HintType.Error)
            death_link_enabled = false
            MakePlayerInexplicablyDie()
        end
    end

    function on_retrieved(map, keys, extra)
        print("Retrieved:")
        -- since lua tables won't contain nil values, we can use keys array
        for _, key in ipairs(keys) do
            print("  " .. key .. ": " .. tostring(map[key]))
        end
        -- extra will include extra fields from Get
        print("Extra:")
        for key, value in pairs(extra) do
            print("  " .. key .. ": " .. tostring(value))
        end
        -- both keys and extra are optional
    end

    function on_set_reply(message)
        print("Set Reply:")
        for key, value in pairs(message) do
            print("  " .. key .. ": " .. tostring(value))
            if key == "value" and type(value) == "table" then
                for subkey, subvalue in pairs(value) do
                    print("    " .. subkey .. ": " .. tostring(subvalue))
                end
            end
        end
    end

    local uuid = ""
    ap = AP(uuid, game_name, server)
    AddHint("Connecting to " .. server .. " ...", HintType.Warning)
    ap:set_socket_connected_handler(on_socket_connected)
    ap:set_socket_error_handler(on_socket_error)
    ap:set_socket_disconnected_handler(on_socket_disconnected)
    ap:set_room_info_handler(on_room_info)
    ap:set_slot_connected_handler(on_slot_connected)
    ap:set_slot_refused_handler(on_slot_refused)
    ap:set_items_received_handler(on_items_received)
    ap:set_location_info_handler(on_location_info)
    ap:set_location_checked_handler(on_location_checked)
    ap:set_data_package_changed_handler(on_data_package_changed)
    ap:set_print_handler(on_print)
    ap:set_print_json_handler(on_print_json)
    ap:set_bounced_handler(on_bounced)
    ap:set_retrieved_handler(on_retrieved)
    ap:set_set_reply_handler(on_set_reply)
end

function connectToAp(host, slot, password)
    ExecuteAsync(function()
        connect(host, slot, password)
    end)

    LoopAsync(200, function()
        if ap == nil then return false end
        ap:poll()
        -- AddHint("Polling!", HintType.Info)
        if #LocationsToCheck > 0 and #LocationsToCheck > #CheckedLocations then
            local only_new_ones = {}
            local i = #CheckedLocations
            while i < #LocationsToCheck do
                table.insert(only_new_ones, LocationsToCheck[i+1])
                i = i + 1
            end
            ap:LocationChecks(only_new_ones)
            for _, APID in ipairs(LocationsToCheck) do
                CheckedLocations[APID] = true
            end
        end

        if GetPendingFuseBlowouts() > 0 then
            TryToBlowoutRandomFuse()
        end
        return false
    end)
end

function disconnect()
    if ap == nil then return end
    CheckedLocations = {}
    item_list = {}
    ap = nil
    have_days = 0
    sold_garbage_bags = 0
    death_link_enabled = false
    for k, _ in pairs(locked_breakers) do locked_breakers[k] = false end
    collectgarbage("collect")
    AddHint("Successfully Disconnected.\nHave a good day!", HintType.Warning)
end

function IsLocationChecked(locationID)
    return CheckedLocations[locationID] ~= nil
end

function GetAPLocationIDfromName(locationName)
    if ap == nil then return nil end
    return ap:get_location_id(locationName)
end

function GetAPNamefromLocationID(locationID)
    if ap == nil then return nil end
    return ap:get_location_name(locationID, nil)
end

function GetAPItemIdFromName(itemName)
    if ap == nil then return nil end
    return ap:get_item_id(itemName)
end

function GetAPItemNameFromId(itemId)
    if ap == nil then return nil end
    return ap:get_item_name(itemId, nil)
end

function ScoutLocationByName(location_name)
    if ap == nil then return end

    local id = GetAPLocationIDfromName(location_name)
    ScoutLocation(id)
end

function ScoutLocation(id)
    if ap == nil then return end
    if id == nil or id < 0 then return end
    if LocationsToScout[id] ~= nil then return end
    print("Scouting location " .. tostring(id))
    ap:LocationScouts({ id }, 0)
    LocationsToScout[id] = true
end

function SendLocation(location_name)
    print("Looking for " .. location_name)
    local id = GetAPLocationIDfromName(location_name)
    return SendLocationId(id)
end

function SendNextLocation(radical)
    print("Looking for next " .. radical)
    local id
    local current = 1
    repeat
        id = GetAPLocationIDfromName(radical .. " " .. current)
        if id == nil or id < 0 then return false end
        current = current + 1
    until not array_contains(LocationsToCheck, id)
    return SendLocationId(id)
end

function SendLocationId(id)
    if id == nil or id < 0 then return false end
    if array_contains(LocationsToCheck, id) or not array_contains(MissingLocations, id) then return false end
    print("Trying to send location " .. tostring(id))
    remove_value(MissingLocations, id)
    add_unique(LocationsToCheck, id)
    local scoutInfo = ScoutedLocations[id]
    if scoutInfo ~= nil then
        ShowAchievementPopup(1, scoutInfo.item .. " for " .. scoutInfo.player, 1, 1)
    else
        ScoutLocation(id)
    end
    return true
end

function ReachGoal()
    if ap == nil then return end
    ap:StatusUpdate(ap.ClientStatus.GOAL)
    AddHint("You have reached your goal, congratulations!", HintType.Info)
    completed = true
end
