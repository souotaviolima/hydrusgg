--[[
    This file may be updated without further advice
    Please, do not modify it

    Este archivo puede actualizarse sin más consejos
    Por favor no lo modifique

    Este arquivo poderá ser atualizado sem aviso prévio
    Por favor, não edite-o
]]

Hydrus = exports[GetCurrentResourceName()]
local Self = Hydrus

Commands = setmetatable({}, {
    __newindex = function(self, key, value)
        exports('custom_command_'..key, value)
    end,
    __index = function(self, key)
        return function(...)
            return Self:run(key, ...)
        end
    end,
})

local locks = {}

function Lock(name, timeout)
    while (locks[name] or 0) > GetGameTimer() do
        Wait(100)
    end
    locks[name] = GetGameTimer() + (timeout or 30000)
    return function()
        locks[name] = nil
    end
end

function SQL(code, args)
    return Self:sql_query(code, args)
end

function Credit(data)
    table.insert(ENV.credits, data)
end

exports('getConfig', function()
    if ENV then
        return ENV
    end
    local message = 'Attempted to call getConfig, but this script is not supposed to have one (config.lua)'
    print(message)
    error(message)
end)

Scheduler = {}

function Scheduler.new(playerId, command, ...)
    Self:schedule(playerId, command, { ... })
end

function Scheduler.delete(playerId, command, args)
    Self:unschedule(playerId, command, args)
end

Events = setmetatable({}, {
    __index = function(self, key)
        local array = setmetatable({}, { __index = table })
        self[key] = array
        return array
    end
})

exports('fire', function(name, payload)
    local ok, err = pcall(function()
        for _, handler in ipairs(Events[name]) do
            handler(payload)
        end
    end)

    return ok or err.message
end)

do
    vRP = {}
    local promises, id = {}, 0
    local key = string.format('%s-%x', 'hydrus', os.time())

    setmetatable(vRP, {
        __index = function(self, name)
            local fn = function(...)
                local p = promise.new()
                
                id = id + 1
                promises[id] = p

                TriggerEvent('vRP:proxy', name, {...}, key, id)
                return table.unpack(Citizen.Await(p))
            end

            self[name] = fn
            return fn
        end
    })

    AddEventHandler('vRP:'..key..':proxy_res', function(id, args)
        local promise = promises[id]

        if promise then
            promises[id] = nil
            promise:resolve(args)
        end
    end)
end

function parse_int(str)
    return math.floor(tonumber(str))
end

parseInt = parse_int

function string:split(sep)
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) table.insert(fields, c) end)
    return fields
end

function string:trim()
    return self:match'^%s*(.*%S)' or ''
end

function table.join(...)
    local res = {}

    for _,array in ipairs({...}) do
        for _,v in ipairs(array) do
            table.insert(res, v)
        end
    end

    return res
end

function table.map(t, fn)
    local res = clone_meta(t)

    for k, v in ipairs(t) do
        res[k] = fn(v, k)
    end

    return res
end

function table.pluck(t, key)
    return table.map(t, function(x)
        return x[key]
    end)
end

function table.filter(t, fn)
    local res = clone_meta(t)

    for k, v in ipairs(t) do
        if fn(v, k) then
            table.insert(res, v)
        end
    end

    return res
end

function table.reduce(t, fn, acc)
    for key, value in ipairs(t) do
        acc = fn(acc, value, key)
    end
    return acc
end

function table.sum(t)
    return table.reduce(t, function(acc, value)
        return acc + value
    end, 0)
end

function clone_meta(t)
    return setmetatable({}, getmetatable(t))
end

function collect(t)
    return setmetatable(t, { __index = table })
end

do

    local function range(prefix, from, to, pad)
        local res = {}

        for i=from, to do
            while #(tostring(i)) < pad do
                i = '0'..i
            end
            local key = (prefix .. i)
            table.insert(res, {
                label = prefix .. i,
                value = prefix .. i
            })
        end

        return res
    end

    function compile_houses(raw)
        local options = {}
        for _, part in ipairs(raw:split(',')) do
            local prefix, interval = table.unpack(part:split(':'))
            local head, tail, pad = table.unpack(interval:split('-'))
            if not tail then
                tail = head
            end
            options = table.join(options, range(prefix, parse_int(head), parse_int(tail), parse_int(pad or 2)))
        end

        local compact = {}

        for _, item in ipairs(options) do
            compact[item.value] = item.label
        end

        return compact
    end

end