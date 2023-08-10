--[[

Author: tochnonement
Email: tochnonement@gmail.com

11/08/2023

--]]

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
    else
        -- ply:EmitSound('luafootsteps/scp/concrete1.wav')
        -- return true
    end
end)

-- Entity(2):SetPos(Entity(1):GetPos())