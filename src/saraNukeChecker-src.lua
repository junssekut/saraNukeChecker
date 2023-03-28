---@class config
local config = {
    --- Warning: Using hooks require older version of Pandora (v2.01).

    --- Use hook or not to detect nuked worlds, if you wish to use hook
    --- it's faster but sometimes force close might happen.
    hook = true,

    --- World names to check, only the world name.
    worlds = {
        'worldname1',
        'worldname2'
    },

    --- Webhook to send the information into.
    webhook = ''
}

---@class WorldData
---@field public NAME string
---@field public NUKED boolean

---@class saraNukeChecker
local saraNukeChecker = { _VERSION = '1.0', _AUTHOR = 'junssekut#4964', _CONTRIBUTORS = {} }

---@class EventHandler
local EventHandler = {}

local request = _G.request
local addHook = _G.addHook
local webhook = _G.webhook
local sleep = _G.sleep

local assert = _G.assert
local load = _G.load
local tinsert = table.insert
local sformat = string.format

local saraCore = assert(load(request('GET', 'https://raw.githubusercontent.com/junssekut/saraCore/main/src/saraCore.lua'))())

local warp = saraCore.WorldHandler.warp --[[@as function]]
local tassertv = saraCore.AssertUtils.tassertv --[[@as function]]
local ldate = saraCore.Date --[[@as function]]
local jencode = saraCore.Json.encode --[[@as function]]
local isprites = saraCore.ItemSprites --[[@as table]]

local cache_world

local checked

---@type WorldData[]
local checked_worlds

---
---Execute to check whether the world is nuked or not.
---
---@param world string
local function execute(world)
    tassertv('execute<world>', world, 'string')

    world = world:upper()

    local warp_result

    if config.hook then
        warp_result = warp(cache_world, '', 1, 1)

        local fail_safe = 0

        while not checked do
            if fail_safe > 60 then break end

            fail_safe = fail_safe + 1

            sleep(1000)
        end
    end

    if not config.hook then
        warp_result = warp(cache_world)

        if not warp_result then
            EventHandler.onNukedWorld(cache_world)
        else
            EventHandler.onValidWorld(cache_world)
        end
    end

    cache_world = nil
    checked = nil
end

---
---Event when a nuked world is detected.
---
---@param world string
function EventHandler.onNukedWorld(world)
    local bot = getBot()

    webhook({
        url = config.webhook,
        avatar = 'https://raw.githubusercontent.com/junssekut/saraNukeChecker/main/img/saraNukeChecker.png',
        username = 'saraNukeChecker',
        content = sformat('[**%s**] %s: %s', bot.world, bot.name, sformat('The world %s is nuked!', world))
    })

    tinsert(checked_worlds, { NAME = world, NUKED = true } --[[@as WorldData]])
end

---
---Event when a valid world is detected ( not nuked ).
---
---@param world string
function EventHandler.onValidWorld(world)
    tinsert(checked_worlds, { NAME = world, NUKED = false } --[[@as WorldData]])
end

---
---Initialize and run the script.
---
---@param config_value config
function saraNukeChecker.init(config_value)
    tassertv('saranukechecker:init<config_value>', config_value, 'table')

    config = config_value

    if #config.worlds == 0 then error('Config Error: Key `worlds` is an empty table. Set the worlds first?', 0) end

    checked_worlds = {}

    if config.hook then
        addHook('onvarlist', function(var)
            if not checked then
                if var[0] == 'OnConsoleMessage' then
                    if var[1] == 'That world is inaccessible.' then
                        EventHandler.onNukedWorld(cache_world)

                        checked = true
                        return true
                    end

                    if var[1]:match(cache_world) then
                        EventHandler.onValidWorld(cache_world)

                        checked = true
                        return true
                    end
                end
            end
        end)
    end

    for i = 1, #config.worlds do
        cache_world = config.worlds[i]

        execute(cache_world)

        sleep(5000)
    end

    local fields = {
        { name = 'World Name', value = '', inline = true },
        { name = 'Nuked Status', value = '', inline = true },
    }

    for i = 1, #checked_worlds do
        local world_data = checked_worlds[i]

        if world_data.NUKED then
            fields[1].value = fields[1].value .. isprites.GLOBE .. ' ' .. world_data.NAME .. '\n'
            fields[2].value = fields[2].value .. isprites.NUKED .. ' NUKED' .. '\n'
        end
    end

    webhook({
        url = config.webhook,
        username = 'saraNukeChecker',
        avatar = 'https://raw.githubusercontent.com/junssekut/saraNukeChecker/main/img/saraNukeChecker.png',
        embed = jencode({
            title = sformat('NUKE CHECKER SUMMARY'),
            color = 16777214,
            fields = fields,
            footer = saraCore.WebhookHandler.getDefaultFooter(),
            timestamp = ldate(true):fmt('${iso}')
        }) --[[@as string]]
    })
end

return saraNukeChecker.init(config)