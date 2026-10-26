local modifierScript = GameMain:GetMod("_ModifierScript")
local modifierClass = modifierScript:GetModifier("modifier_fivebasedan")

function modifierClass:Enter(modifier, npc)
    xlua.private_accessible(CS.XiaWorld.Modifier.ModifierBase)
    modifier.Version = 0
    modifier:ModifyBaseFive(npc.PropertyMgr, modifier.Scale)
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
