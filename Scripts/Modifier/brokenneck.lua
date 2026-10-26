local modifierScript = GameMain:GetMod("_ModifierScript")
local modifierClass = modifierScript:GetModifier("modifier_brokenneck")

function modifierClass:Enter(modifier, npc)
    local practice = npc.PropertyMgr.Practice
    if practice and practice.CurNeck
        and practice.CurNeck.Kind ~= CS.XiaWorld.g_emGongBottleNeckType.Die then
        practice:BrokenNeck(false)
    end
end

function modifierClass:Step(modifier, npc, dt)
end

function modifierClass:UpdateStack(modifier, npc, add)
end

function modifierClass:Leave(modifier, npc)
end

function modifierClass:OnGetSaveData()
    return nil
end

function modifierClass:OnLoadData(modifier, npc, data)
end
