-- Shared language must load before any standalone window.
pcall(require, 'Scripts/Xaou_Language.lua')

-- NPC data and action services must load before the standalone UI reads them.
pcall(require, 'Scripts/Xaou_NpcHelper.lua')
pcall(require, 'Scripts/Xaou_NpcActions.lua')
pcall(require, 'Scripts/Xaou_NpcCommands.lua')
pcall(require, 'Scripts/Xaou_GodPractice_Window.lua')
pcall(require, 'Scripts/Xaou_BodyPractice_Window.lua')
pcall(require, 'Scripts/Xaou_LearnFullGong_Core.lua')
pcall(require, 'Scripts/Xaou_LibraryLearn_Core.lua')
pcall(require, 'Scripts/Xaou_LearnWindow.lua')
pcall(require, 'Scripts/Xaou_BulkEsoterica_Core.lua')
pcall(require, 'Scripts/Xaou_BulkEsoterica_Window.lua')
pcall(require, 'Scripts/Xaou_BookMenu_Core.lua')
pcall(require, 'Scripts/Xaou_BookMenu_Window.lua')
pcall(require, 'Scripts/Xaou_WorldTools_Core.lua')
pcall(require, 'Scripts/Xaou_WorldTools_Window.lua')
pcall(require, 'Scripts/Xaou_MapTools_Window.lua')
pcall(require, 'Scripts/Xaou_Fps_Window.lua')
pcall(require, 'Scripts/Xaou_Temperature_Window.lua')
pcall(require, 'Scripts/XaouBossSummonWindow.lua')
pcall(require, 'Scripts/Xaou_TaiyiBox_Core.lua')
pcall(require, 'Scripts/Xaou_PetGrowth_Core.lua')
pcall(require, 'Scripts/Xaou_DamageNumbers.lua')
pcall(require, 'Scripts/Xaou_SchoolCapacity.lua')
pcall(require, 'Scripts/Xaou_ModCenter_Window.lua')
pcall(require, 'Scripts/Xaou_NpcManager_Window.lua')
pcall(require, 'Scripts/Xaou_JianghuRelations_Ready.lua')

local XaouModCenterStandalone = GameMain:NewMod("XaouModCenterStandalone")
local XaouFpsFrames, XaouFpsStarted = 0, nil

function XaouModCenterStandalone:OnRender(dt)
    XaouFpsFrames = XaouFpsFrames + 1
    local now = nil
    pcall(function() now = tonumber(CS.UnityEngine.Time.realtimeSinceStartup) end)
    if now == nil then return end
    if XaouFpsStarted == nil then XaouFpsStarted = now; return end
    local elapsed = now - XaouFpsStarted
    if elapsed < 0.5 then return end
    Xaou_ActualFps = XaouFpsFrames / elapsed
    XaouFpsFrames = 0
    XaouFpsStarted = now
    if Xaou_RefreshFpsDisplay then pcall(Xaou_RefreshFpsDisplay) end
end

function XaouModCenterStandalone:OnEnter()
    local event = GameMain:GetMod("_Event")
    event:RegisterEvent(g_emEvent.SelectNpc, function(evt, npc, objs)
        if npc ~= nil and npc.ThingType == g_emThingType.Npc then
            npc:RemoveBtnData("Xaou")
            npc:AddBtnData(
                "Xaou",
                "res/Sprs/ui/icon_hand",
                "GameMain:GetMod('XaouModCenterStandalone'):Open(bind)",
                Xaou_T and Xaou_T("เปิดศูนย์รวมเครื่องมือของ Xaou", "Open Xaou Mod Center") or "เปิดศูนย์รวมเครื่องมือของ Xaou",
                nil
            )
        end
    end, "XaouModCenterStandalone_SelectNpc")
end

function XaouModCenterStandalone:Open(npc)
    if Xaou_OpenStandaloneModCenter ~= nil then
        local ok, value = pcall(function() return Xaou_OpenStandaloneModCenter(npc) end)
        if ok and value ~= false then return end
        pcall(function()
            local message = "เปิด Xaou Mod Center ไม่สำเร็จ\n" .. tostring(value)
            if Xaou_LocalizeText then message = Xaou_LocalizeText(message) end
            world:ShowMsgBox(message)
        end)
    end
end
