callback = {}
local cbEvent = ("__x-radiolist_cb_%s")

local function callbackResponse(success, result, ...)
    if not success then
        if result then
            return print(("^1SCRIPT ERROR: %s^0\n%s"):format(result , Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString()) or ""))
        end

        return false
    end

    return result, ...
end

local pcall = pcall

function callback.register(name, cb)
    RegisterNetEvent(cbEvent:format(name), function(resource, key, ...)
        TriggerClientEvent(cbEvent:format(resource), source, key, callbackResponse(pcall(cb, source, ...)))
    end)
end