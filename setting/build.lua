local fs = require 'bee.filesystem'

local json = require 'json-beautify'
local configuration = require 'package.configuration'
local fsu  = require 'fs-utility'

local function addSplited(t, key, value)
    t[key] = value
    local left, right = key:match '([^%.]+)%.(.+)'
    if not left then
        return
    end
    local nt = t[left] or {
        properties = {}
    }
    t[left] = nt
    addSplited(nt.properties, right, value)
end

local function copyWithNLS(t, callback)
    local nt = {}
    for k, v in pairs(t) do
        if type(v) == 'string' then
            v = callback(v) or v
        elseif type(v) == 'table' then
            v = copyWithNLS(v, callback)
        end
        if type(k) == 'string' and k:sub(1, #'Lua.') == 'Lua.' then
            local ref = {
                ['$ref'] = '#/properties/' .. k
            }
            addSplited(nt, k, ref)
            addSplited(nt, k:sub(#'Lua.' + 1), ref)
        end
        nt[k] = v
    end
    return nt
end

local encodeOption = {
    newline = '\r\n',
    indent  = '    ',
}
for _, lang in ipairs {'', '-zh-cn'} do
    local nls = require('package.nls' .. lang)

    local setting = {
        ['$schema'] = '',
        title       = 'setting',
        description = 'Setting of sumneko.lua',
        type        = 'object',
        properties  = copyWithNLS(configuration, function (str)
            return str:gsub('^%%(.+)%%$', nls)
        end),
    }

    fsu.saveFile(fs.path'setting/schema'..lang..'.json', json.beautify(setting, encodeOption))
end
