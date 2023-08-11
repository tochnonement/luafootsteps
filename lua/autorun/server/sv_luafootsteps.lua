--[[

Author: tochnonement
Email: tochnonement@gmail.com

11/08/2023

--]]

local CONVAR_SV_FORCE = CreateConVar('sv_luafootsteps_force_enabled', '0', {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, '', 0, 1)
local CONVAR_SV_PACK = CreateConVar('sv_luafootsteps_force_pack', 'default', {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})

do
    local files = file.Find('luafootstep_packs/*', 'LUA')
    for _, name in ipairs(files) do
        AddCSLuaFile('luafootstep_packs/' .. name)
    end
end

util.AddNetworkString('LuaFootsteps.SP_Send')
hook.Add('PlayerFootstep', 'LuaFoosteps.SupportSinglePlayer', function(ply, pos, foot, soundPath, volume)
    if (game.SinglePlayer()) then
        net.Start('LuaFootsteps.SP_Send')
            net.WriteVector(pos)
            net.WriteBit(foot)
            net.WriteString(soundPath)
            net.WriteFloat(volume)
        net.Send(ply)

        return true
    end
end)