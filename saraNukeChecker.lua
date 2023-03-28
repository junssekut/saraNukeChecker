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

--- Fetch the online script and load it.
local saraNukeChecker = assert(load(request('GET', 'https://raw.githubusercontent.com/junssekut/saraNukeChecker/main/src/saraNukeChecker-src.lua'))())

--- Initialize with your custom config!
local status, message = pcall(saraNukeChecker.init, config)

if not status then error('An error occured, please see error_logs.txt\n' .. message) end