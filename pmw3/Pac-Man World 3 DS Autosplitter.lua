-- Autosplitter for Pac-Man World 3 DS - @inconsistent_dg
-- Adapted from Trysdyn Black's autosplitters https://github.com/trysdyn/bizhawk-speedrun-lua/
-- Requires LiveSplit 1.7+. Only tested on BizHawk 2.9.1

local current_level = -1
local in_title_screen = true
local boss_hp = 0
local boss_hp_initialized = false

local function init_livesplit()
    local rom_hash = gameinfo.getromhash()
    
    -- Check region
    if rom_hash == "40A92219FB2D1F5905E1CF18684690AF" then -- US
        title_screen_address = 0x148E57
        level_address = 0x086D34
        boss_hp_address = 0x26C568
    elseif rom_hash == "C64BDA6908D73D65973E994ED9363DEC" then -- EU
        title_screen_address = 0x149A97
        level_address = 0x0862F4
        boss_hp_address = 0x271B48
    else -- Error if neither
        error("\nLoaded ROM isn't DS PMW3!\n" ..
              "Make sure to run an official version of DS PMW3,\n" .. 
              "then load this script again")
    end

    pipe_handle = io.open("//./pipe/LiveSplit", 'a')

    if not pipe_handle then
        error("\nFailed to open LiveSplit named pipe!\n" ..
              "Please make sure LiveSplit is running and is at least 1.7, " ..
              "then load this script again")
    end

    pipe_handle:write("reset\r\n")
    pipe_handle:flush()

    return pipe_handle
end

local function write_to_livesplit(command)
    if pipe_handle then
        pipe_handle:write(command .. "\r\n")
        pipe_handle:flush()
    else
        error("pipe_handle is not initialized")
    end
end

local function check_title_screen()
    local title_screen = memory.readbyte(title_screen_address)
    if title_screen == 1 then
        if not in_title_screen then
            -- Reset when going back to title screen
            write_to_livesplit("reset")
        end
        in_title_screen = true
    else
        if in_title_screen then
            -- Start timer when leaving title screen
            write_to_livesplit("starttimer")
            in_title_screen = false
        end
    end
end

local function check_level()
    local new_level = memory.readbyte(level_address)
    if new_level > current_level and new_level ~= 16 then
        -- Split when the level increases, except when the level is 16
        -- The 2nd half of Gogekka Heights is 16, so it shouldn't split
        write_to_livesplit("split")
    end

    if new_level == 16 then
        -- Set the current level back to 7 after level 16
        -- So the the rest of the splits work normally
        current_level = 7
    else
        current_level = new_level
    end
end

local function check_final_boss()
    local new_boss_hp = memory.readbyte(boss_hp_address)
    if current_level == 13 then
        if new_boss_hp == 3 then
            boss_hp_initialized = true
        elseif new_boss_hp == 0 and boss_hp_initialized then
            -- Time ends when boss HP goes to 0 after being initialized to 3
            write_to_livesplit("split")
            boss_hp_initialized = false -- Reset the flag after the split
        end
    end
    boss_hp = new_boss_hp
end

local pipe_handle = nil
local success, err = pcall(function()
    pipe_handle = init_livesplit()
end)

if not success then
    print(err)
    return
end

memory.usememorydomain("Main RAM") -- Required for NDS memory grabs

while true do
    check_title_screen()
    check_level()
    check_final_boss()
    emu.frameadvance()
end
