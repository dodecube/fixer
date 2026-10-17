local AP_NOTEBOOK = nil
function GetAPNotebook()
    if AP_NOTEBOOK == nil then
        AP_NOTEBOOK = FindAPNotebook()
        if AP_NOTEBOOK then return AP_NOTEBOOK end
        print("Creating new AP notebook")

        local out = {}
        GetGameMode():spawnPropThroughGamemode(
            FName("clipboard"),
            -- On the black cube underneath Alpha Base
            { ["Translation"] = { X = -415, Y = -1560, Z = -3346 }, ["Scale3D"] = { ["X"] = 1.0, ["Y"] = 1.0, ["Z"] = 1.0 } },
            1,
            out
        )
        AP_NOTEBOOK = out["actor "]
        AP_NOTEBOOK.Key = FName("__AP_NOTEBOOK__")
        SaveDataToNotebook()
        AP_NOTEBOOK:upd()
    elseif not AP_NOTEBOOK:IsValid() then
        return nil  -- We had a notebook but we lost it: wait for it
    end
    return AP_NOTEBOOK
end

function FindAPNotebook()
    local notebooks = FindAllOf("prop_notebook_C") or {}
    for _, notebook in ipairs(notebooks) do
        if notebook.Key:ToString() == "__AP_NOTEBOOK__" then
            print("Found AP notebook")
            return notebook
        end
    end
    return nil
end

local received_items = 0
local sold_garbage_bags = 0
local checked_location_names = {}
local skip_claimed = {}
local pending_fuse_blowouts = 0

function LoadNotebookData()
    local APNotebook = FindAPNotebook()
    if APNotebook and APNotebook:IsValid() then
        local tokens = {}
        local text = APNotebook.Text[1]:ToString() or ""
        for token in string.gmatch(text, "[^,]*") do
            table.insert(tokens, token)
        end
        if #tokens >= 3 and #tokens[1] > 0 and #tokens[2] > 0 then
            connectToAp(tokens[1], tokens[2], tokens[3])
        else
            AddHint("An AP save was detected but the connection info seems to be invalid. Please reconnect manually", HintType.Warning)
        end

        received_items = tonumber(APNotebook.Text[2]:ToString()) or 0
        sold_garbage_bags = tonumber(APNotebook.Text[3]:ToString()) or 0
        checked_location_names = {}
        for name in string.gmatch(APNotebook.Text[4]:ToString() or "", "[^,]+") do
            table.insert(checked_location_names, name)
        end
        skip_claimed = {}
        for name in string.gmatch(APNotebook.Text[5]:ToString() or "", "[^,]+") do
            table.insert(skip_claimed, name)
        end
        pending_fuse_blowouts = tonumber(APNotebook.Text[6]:ToString()) or 0
    end
end

function SaveDataToNotebook()
    local APNotebook = GetAPNotebook()
    if APNotebook and APNotebook:IsValid() then
        APNotebook.Text[1] = FString(server .. "," .. slot .. "," .. password)
        APNotebook.Text[2] = FString(tostring(received_items))
        APNotebook.Text[3] = FString(tostring(sold_garbage_bags))
        APNotebook.Text[4] = FString(table.concat(checked_location_names, ","))
        APNotebook.Text[5] = FString(table.concat(skip_claimed, ","))
        APNotebook.Text[6] = FString(tostring(pending_fuse_blowouts))
        APNotebook:upd()
    else
        AddHint("AP save failed. Retrying", HintType.Warning)
        ExecuteWithDelay(SaveDataToNotebook, 1000)
    end
end

function GetRecievedItems()
    return received_items
end

function SetRecievedItems(val)
    received_items = val
    print("SAVE RECEIVED ITEMS IS NOW " .. tostring(received_items))
    SaveDataToNotebook()
    return true
end

function GetSoldGarbageBags()
    return sold_garbage_bags
end

function SetSoldGarbageBags(val)
    sold_garbage_bags = val
    print("SAVE SOLD TRASH BAGS IS NOW " .. tostring(sold_garbage_bags))
    SaveDataToNotebook()
    return true
end

function GetCheckedLocationNames()
    return checked_location_names
end

function AddCheckedLocationName(val)
    table.insert(checked_location_names, val)
    print("SAVE CHECKED LOCATIONS IS NOW " .. table.concat(checked_location_names, ","))
    SaveDataToNotebook()
    return true
end

function WasSkipClaimed(val)
    return array_contains(skip_claimed, val)
end

function AddSkipClaimedItem(val)
    table.insert(skip_claimed, val)
    print("SAVE AUTO CLAIMED IS NOW " .. table.concat(skip_claimed, ","))
    SaveDataToNotebook()
    return true
end

function ShiftSkipClaimed()
    table.remove(skip_claimed, 1)
    print("SAVE AUTO CLAIMED IS NOW " .. table.concat(skip_claimed, ","))
    SaveDataToNotebook()
    return true
end

function GetPendingFuseBlowouts()
    return pending_fuse_blowouts
end

function SetPendingFuseBlowouts(val)
    pending_fuse_blowouts = val
    print("SAVE PENDING BLOWOUTS IS NOW " .. tostring(pending_fuse_blowouts))
    SaveDataToNotebook()
    return true
end
