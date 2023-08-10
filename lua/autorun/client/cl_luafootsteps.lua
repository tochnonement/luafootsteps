--[[

Author: tochnonement
Email: tochnonement@gmail.com

11/08/2023

--]]

LuaFootsteps = LuaFootsteps or {
    __VERSION = 20230811,
    __LICENSE = [[
        MIT License

        Copyright (c) 2023 Aleksandrs Filipovskis

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the 'Software'), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    ]]
}
LuaFootsteps.packs = LuaFootsteps.packs or {}
LuaFootsteps.panels = LuaFootsteps.panels or {}

local LuaFootsteps = LuaFootsteps
local CONVAR_ENABLED = CreateClientConVar('cl_luafootsteps_enabled', '1', true)
local CONVAR_ID = CreateClientConVar('cl_luafootsteps_pack', 'default', true)

--[[------------------------------
Returns the current's pack which is active
    If you want to override some logic check this function
--------------------------------]]
function LuaFootsteps:GetCurrentPackID()
    local id = CONVAR_ID:GetString()
    if (self.packs[id]) then
        return id
    end
    return 'default'
end

function LuaFootsteps:GetCurrentPackTable()
    return self.packs[ self:GetCurrentPackID() ]
end

--[[------------------------------
A function to create a new pack
--------------------------------]]
function LuaFootsteps:Pack(id, data)
    assert(isstring(id), string.format('bad argument #1 (expected string, got %s)', type(id)))
    assert(istable(data), string.format('bad argument #2 (expected table, got %s)', type(data)))

    -- required due to the loading process
    local data = table.Copy(data)

    data.ID = id
    data.Class = id

    -- precache amount
    for materialName, sounds in pairs(data.Sounds) do
        sounds.count = #sounds
    end

    self.packs[id] = data

    print('[LuaFootsteps] Registered a new pack: ' .. data.Name .. '(' .. id .. ')')
end

function LuaFootsteps:Load()
    local files = file.Find('luafootstep_packs/*', 'LUA')
    for _, name in ipairs(files) do
        _G.PACK = {Sounds = {}}
        
        include('luafootstep_packs/' .. name)

        _G.PACK = nil
    end
end

LuaFootsteps:Load()

--[[------------------------------
//ANCHOR Controllers
--------------------------------]]
do
    local gsub = string.gsub
    local match = string.match
    local notifs = {}
    local cache = {}

    hook.Add('EntityEmitSound', 'LuaFootsteps.Controller', function(data)
        if (not data.OriginalSoundName:find('footsteps')) then return end
        if (not CONVAR_ENABLED:GetBool()) then 
            return 
        end

        local soundPath = data.OriginalSoundName
        local cleanName = match(soundPath, '([%w_]+)%.')
        local materialName = gsub(cleanName, '%d', '')
        local pack = LuaFootsteps:GetCurrentPackTable()

        local found = pack.Path .. cleanName .. pack.Extension

        cache[found] = cache[found] or file.Exists('sound/' .. found, 'GAME')

        local exists = cache[found]

        if (exists) then
            data.SoundName = found
            return true
        else
            notifs[pack.ID] = notifs[pack.ID] or {}
            if (not notifs[pack.ID][materialName]) then
                print('[LuaFootsteps] [Warning] Missing footstep for material: ' .. materialName)
                notifs[pack.ID][materialName] = true
            end
        end
    end)
end

net.Receive('LuaFootsteps.SP_Send', function()
    local ply = LocalPlayer()
    local pos = net.ReadVector()
    local foot = net.ReadBit()
    local soundPath = net.ReadString()
    local volume = net.ReadFloat()

    ply:EmitSound(soundPath, 75, 100, volume, CHAN_BODY)
end)

--[[------------------------------
Menu
--------------------------------]]
hook.Add('AddToolMenuCategories', 'LuaFootsteps', function()
	spawnmenu.AddToolCategory('Utilities', 'LuaFootsteps', 'LuaFootsteps')
end)

local MATERIALS = {}
MATERIALS['wood'] = true
MATERIALS['woodpanel'] = true
MATERIALS['concrete'] = true
MATERIALS['glass_sheet_step'] = true
MATERIALS['tile'] = true
MATERIALS['dirt'] = true
MATERIALS['metal'] = true
MATERIALS['metalgrate'] = true
MATERIALS['grass'] = true
MATERIALS['ladder'] = true
MATERIALS['sand'] = true
MATERIALS['gravel'] = true
MATERIALS['wade'] = true -- water
MATERIALS['slosh'] = true -- water

do
    local panels = LuaFootsteps.panels

    local function addInfo(id, form, title, text, titleColor)
        local panel = vgui.Create('Panel', form)
        panel:Dock(TOP)
        panel:SetMouseInputEnabled(false)
        panel.Paint = function() end
        panel:DockMargin( 8, 0, 8, 4 )

        local lblTitle = vgui.Create('DLabel', panel)
        lblTitle:SetText(title)
        lblTitle:SetTextColor(titleColor)
        lblTitle:SetContentAlignment(4)
        lblTitle:Dock(FILL)

        local lblValue = vgui.Create('DLabel', panel)
        lblValue:SetText(text)
        lblValue:SetTextColor(titleColor)
        lblValue:SetContentAlignment(6)
        lblValue:Dock(RIGHT)
        lblValue:SetWide(ScrW() * .03)
        lblValue:SetExpensiveShadow(1, Color(0, 0, 0, 155))
        
        panel.lblTitle = lblTitle
        panel.lblValue = lblValue
        panels[id] = panel
    end

    local function update()
        local pack = LuaFootsteps:GetCurrentPackTable()
        local sounds = file.Find('sound/' .. pack.Path .. '*', 'GAME')

        if (IsValid(panels.amount)) then
            panels.amount.lblValue:SetText(#sounds)
        end
        
        for id in pairs(MATERIALS) do
            local example = id .. '1' .. pack.Extension
            local exists = table.HasValue(sounds, example)
            if (IsValid(panels[id])) then
                panels[id].lblValue:SetText(exists and 'CUSTOM' or 'GMOD')
                panels[id].lblValue:SetTextColor(exists and Color(97, 238, 78) or Color(223, 75, 75))
            end
        end
    end

    hook.Add('PopulateToolMenu', 'LuaFootsteps', function()
        spawnmenu.AddToolMenuOption( 'Utilities', 'LuaFootsteps', 'settings', 'Settings', '', '', function( panel )
            panel:Clear()
            panel:CheckBox('Enable the addon', 'cl_luafootsteps_enabled')
            local combo, label = panel:ComboBox('Selected pack', 'cl_luafootsteps_pack')
    
            for _, pack in pairs(LuaFootsteps.packs) do
                combo:AddChoice(pack.Name, pack.ID)
            end

            panel:ControlHelp('INFORMATION')
    
            addInfo('amount', panel, 'Sound Amount', '0', color_black)

            for id in pairs(MATERIALS) do
                addInfo(id, panel, 'Sound (' .. id:upper() .. ')', '0', color_black)
            end
            
            timer.Simple(engine.TickInterval(), function()
                if (IsValid(panel)) then
                    update()
                end
            end)

        end)
    end)

    cvars.AddChangeCallback('cl_luafootsteps_pack', function()
        timer.Simple(0, function()
            update()
        end)
    end, 'UpdatePanels')
end