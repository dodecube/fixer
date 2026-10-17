function array_contains(arr, val)
    for index, value in ipairs(arr) do
        if value == val then
            return true
        end
    end
    return false
end

function add_unique(arr, val)
    if not array_contains(arr, val) then
        table.insert(arr, val)
    end
end

function remove_value(arr, val)
    for i=1,#arr do
        if arr[i] == val then
            table.remove(arr, i)
            break
        end
    end
end

function any(arr, predicate)
    for i,v in ipairs(arr) do
        if predicate(v, i) then return true end
    end
    return false
end

function table_invert(t)
    local s={}
    for k,v in pairs(t) do
      s[v]=k
    end
    return s
end

function lowercase_keys(t)
    local s={}
    for k,v in pairs(t) do
      s[string.lower(k)]=v
    end
    return s
end

function extract_keys(original_table)
    local keys_only_table = {}
    for k, v in pairs(original_table) do -- Iterate over all key-value pairs
        table.insert(keys_only_table, k) -- Insert the key 'k' into the new table as a value
    end
    return keys_only_table
end

local existing_hooks = {}
function RegisterUniqueHook(hook, func)
    if not array_contains(existing_hooks, hook) then
        table.insert(existing_hooks, hook)
        RegisterHook(hook, func)
    end
end

function NotifyUniqueOnNewObject(cls, func)
    if not array_contains(existing_hooks, cls) then
        table.insert(existing_hooks, cls)
        NotifyOnNewObject(cls, func)
    end
end

function string.startswith(str, match)
   return string.sub(str, 1, string.len(match)) == match
end
